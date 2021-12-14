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
  COMPLETED_ID=($(curl -X POST 'https://api.notion.com/v1/databases/'$DATABASE_ID'/query' \
      -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
      -H 'Notion-Version: 2021-05-13' \
      -H "Content-Type: application/json" \
      --data '{
        "filter": {
            "property": "Status",
            "select": {
              "equals": "Completed"
          }
        }
      }' \
    | jq -r '[.results[].id] | @sh' | tr -d \'\"))
  echo $COMPLETED_ID
}

function delete_completed {
  get_completed_ids
  for item in "${COMPLETED_ID[@]}" ; do
    URL="https://api.notion.com/v1/blocks/${item}"

    RESULT=$(curl -X DELETE $URL \
      -H 'Authorization: Bearer '"$NOTION_API_KEY"'' \
      -H 'Notion-Version: 2021-08-16' \
    | jq -r '.archived')
    echo $RESULT
  done
}

while [ $# -gt 0 ]; do

  case ${1} in
    --debug|-d)
        set -x
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
