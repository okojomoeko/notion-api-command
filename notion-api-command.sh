function usage {
    cat <<EOF
$(basename ${0}) is a tool for ...

Usage:
    $(basename ${0}) [command] [<options>]

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

function delete_archive {

  DELETE_ID=($(curl -X POST 'https://api.notion.com/v1/databases/'$DATABASE_ID'/query' \
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

  for item in "${DELETE_ID[@]}" ; do
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

    --delete_archive)
      DELETE_ARCHIVE_FLAG="TRUE"
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
  if [ "$DELETE_ARCHIVE_FLAG" = "TRUE" ] ; then
    delete_archive
  else
    echo "[ERROR] No command"
  fi
fi
