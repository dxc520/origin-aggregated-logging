#!/bin/bash

# This is a test suite for the eventrouter

source "$(dirname "${BASH_SOURCE[0]}" )/../hack/lib/init.sh"
source "${OS_O_A_L_DIR}/hack/testing/util.sh"
os::test::junit::declare_suite_start "test/eventrouter"

function warn_nonformatted() {
    local es_svc=$1
    local index=$2
    # check if eventrouter and fluentd with correct ViaQ plugin are deployed
    local non_formatted_event_count=$( curl_es $es_svc /$index/_count?q=verb:* | get_count_from_json )
    if [ "$non_formatted_event_count" != 0 ]; then
        os::log::warning "$non_formatted_event_count events from eventrouter in index $index were not processed by ViaQ fluentd plugin"
    fi
}
function get_eventrouter_pod() {
    oc get pods --namespace=default -l component=eventrouter --no-headers | awk '$3 == "Running" {print $1}'
}

evpod=$( get_eventrouter_pod )
if [ -z "$evpod" ]; then
    os::log::warning "Eventrouter not deployed"
else
    essvc=$( get_es_svc es )
    esopssvc=$( get_es_svc es-ops )
    esopssvc=${esopssvc:-$essvc}

    warn_nonformatted $essvc '/project.*'
    warn_nonformatted $esopssvc '/.operations.*/'

    os::cmd::expect_success_and_not_text "curl_es $esopssvc /.operations.*/_count?q=kubernetes.event.verb:* | get_count_from_json" "^0\$"
fi
