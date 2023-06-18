#!/bin/bash

function usage {
    cat <<EOF

$(basename ${0}) is a tool for Notion API

Usage:
    $(basename ${0}) [command] [<options>]
    [command]
      get_completed:    Get block id which property is tagged with "Completed"
      delete_completed: Delete block which property is tagged with "Completed"

Options:
    --version, -v     print $(basename ${0}) version
    --help, -h        print this
    --database_id     notion database id
    --token           notion integration token
EOF
}

function version {
  echo "$(basename ${0}) version 0.0.1 "
}

function get_completed_ids {
  comp_ids=$(curl -X POST 'https://api.notion.com/v1/databases/'$DATABASE_ID'/query' \
      -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
      -H "Content-Type: application/json" \
      -H "Notion-Version: 2022-06-28" \
      --data '{
        "filter": {
            "property": "Status",
            "status": {
              "equals": "Completed"
          }
        }
      }' \
    | jq -r '.results[].id')
  echo $comp_ids
}

function delete_completed {
  comp_ids=($(get_completed_ids))
  for id in "${comp_ids[@]}" ; do
    result=$(curl https://api.notion.com/v1/pages/$id \
    -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
    -H "Content-Type: application/json" \
    -H "Notion-Version: 2022-06-28" \
    -X PATCH \
      --data '{
      "archived": true
    }')
    echo $result
  done
}

function configure {
  mkdir -p $HOME/.config/nac
  read -sp "Enter your DATABASE_ID: " DATABASE_ID
  echo ""
  read -sp "Enter your NOTION_API_KEY: " NOTION_API_KEY
  (echo "DATABASE_ID=$DATABASE_ID"; echo "NOTION_API_KEY=$NOTION_API_KEY") > $HOME/.config/nac/cred
  # echo "NOTION_API_KEY=$NOTION_API_KEY" > $HOME/.config/nac/cred
}

set -a
source $HOME/.config/nac/cred
set +a

while [ $# -gt 0 ]; do

  case ${1} in
    --debug|-d)
        set -x
    ;;

    configure)
      configure
      exit 0
    ;;

    get_completed)
      COMMAND_FLAG="GET_COMPLETED"
    ;;

    delete_completed)
      COMMAND_FLAG="DELETE_COMPLETED"
    ;;

    --database_id)
        DATABASE_ID=${2}
        shift
    ;;

    --token)
        NOTION_API_KEY=${2}
        shift
    ;;

    help|--help|-h)
      usage
    ;;

    version|--version|-v)
        version
    ;;

    *)
        echo "[ERROR] Invalid option '${1}'"
        usage
        exit 1
    ;;
  esac
  shift
done



if [ ! -z "$DATABASE_ID" ] && [ ! -z "$NOTION_API_KEY" ] ; then

  case "$COMMAND_FLAG" in
    "GET_COMPLETED")
      get_completed_ids
    ;;
    "DELETE_COMPLETED")
      delete_completed
    ;;
    *)
      echo "[ERROR] No command"
      usage
      exit 1
    ;;
  esac
fi
