#!/bin/bash

outputfile="zwatcheroutput.txt"
tmpoutput=".tmpzwatcheroutput.txt"

RESET="\e[0m"
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
CYAN="\e[1;36m"

displaybanner() {
    echo -e "${GREEN}"
cat << "BANNER"
███████╗██╗    ██╗████████╗ ██████╗██╗  ██╗██████╗ 
╚══███╔╝██║    ██║╚══██╔══╝██╔════╝██║  ██║██╔══██╗
  ███╔╝ ██║ █╗ ██║   ██║   ██║     ███████║██████╔╝
 ███╔╝  ██║███╗██║   ██║   ██║     ██╔══██║██╔══██╗
███████╗╚███╔███╔╝   ██║   ╚██████╗██║  ██║██║  ██║
╚══════╝ ╚══╝╚══╝    ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ v1.2
                       BY H1NTR0X01 @71ntr
  Security is a myth. Hacking is not.
BANNER
    echo -e "${RESET}"
}

displayusage() {
    echo -e "${CYAN}Usage: zwatcher.sh [OPTIONS]"
    echo -e "Options:"
    echo -e "  -u <domain or URL>           Specify a single domain to scan"
    echo -e "  -l <list of domains>         Specify a file containing a list of domains to scan"
    echo -e "  -s <interval>                Specify the scan interval in seconds"
    echo -e "  -n <notify-id>               Specify the notification ID"
    echo -e "  -o <output file>             Specify the output file to save scan results"
    echo -e "  -h                           Display this help message"
    echo -e "\n${RED}./zwatcher.sh -u example.com -s 60 -o scanresults.txt -n notifyid"
}

runhttpx() {
    if [ -e "$outputfile" ]; then
        echo -e "${GREEN}Scanning existing targets.${RESET}"
    else
        echo -e "${RED} Creating $outputfile.${RESET}"
        httpx -silent -sc -cl -title -u "$DOMAIN" | tee "$outputfile"
        echo -e "${GREEN}First scan completed & saved to $outputfile${RESET}"
    fi
    httpx -silent -sc -cl -title -u "$DOMAIN" > "$tmpoutput"
}

comparescans() {
    diffoutput=$(cat "$tmpoutput" | anew "$outputfile")
    
    if [ -z "$diffoutput" ]; then
        echo -e "${YELLOW}Nothing new found.${RESET}"
        echo -e "${CYAN}Sleeping for $SLEEP_INTERVAL seconds.${RESET}"
    else
        echo -e "${CYAN}New targets found:${RESET}"
        echo -e "${CYAN}$diffoutput${RESET}"
        echo -e "${CYAN}zwatcher found: $diffoutput${RESET}" | notify -id "$notifyid" > /dev/null 2>&1
    fi
}

scanfordomainslist() {
    while read -r domain; do
        DOMAIN="$domain"
        runhttpx
        while true; do
            runhttpx
            comparescans
            sleep "$SLEEP_INTERVAL"
        done
    done <"$LIST_FILE"
}

if [ $# -eq 0 ]; then
    displaybanner
    displayusage
    exit 1
fi

outputfile_valid="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u) DOMAIN="$2"; shift ;;
        -l)
            LIST_FILE="$2"
            if [ ! -f "$LIST_FILE" ]; then
                echo -e "${RED}File not found: $LIST_FILE${RESET}" >&2
                exit 1
            fi
            shift
            ;;
        -s) SLEEP_INTERVAL="$2"; shift ;;
        -n) notifyid="$2"; shift ;;
        -o)
            outputfile="$2"
            if [ -z "$outputfile" ]; then
                echo -e "${RED}Output file not specified.${RESET}" >&2
                displayusage
                exit 1
            fi
            outputfile_valid="true"
            if [ ! -w "$(dirname "$outputfile")" ]; then
                echo -e "${RED}Cannot write to the specified output file path: $outputfile${RESET}" >&2
                exit 1
            fi
            shift
            ;;
        -h)
            displaybanner
            displayusage
            exit 0
            ;;
        \?)
            echo -e "${RED}Invalid option: -$OPTARG${RESET}" >&2
            displayusage
            exit 1
            ;;
        :)
            echo -e "${RED}Option -$OPTARG requires an argument.${RESET}" >&2
            displayusage
            exit 1
            ;;
    esac
    shift
done

# if [ "$outputfile_valid" == "false" ]; then
#     echo -e "${RED}Output file not specified.${RESET}" >&2
#     displayusage
#     exit 1
# fi

displaybanner

if [ -n "$LIST_FILE" ]; then
    scanfordomainslist
else
    runhttpx
    while true; do
        runhttpx
        comparescans
        sleep "$SLEEP_INTERVAL"
    done
fi
