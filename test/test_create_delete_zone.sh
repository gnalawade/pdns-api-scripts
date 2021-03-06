#@IgnoreInspection BashAddShebang
# Copyright 2017, AppDynamics LLC and its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

testCreateAndDeleteZone(){
    local ZONE_NAME=$(_random_alphanumeric_chars 3).$(_random_alphanumeric_chars 3).tld.
    local PRIMARY_MASTER=primary.master.$ZONE_NAME
    local MASTER_2=secondary.master.$ZONE_NAME
    local MASTER_3=tertiary.master.$ZONE_NAME
    local HOSTMASTER_EMAIL=$(_random_alphanumeric_chars 8)@$ZONE_NAME
    local TTL=85399
    local REFRESH=1199
    local RETRY=179
    local EXPIRY=1209599
    local NEG_TTL=61
    local NS_TTL=1209601
    local DEBUG_FLAG

    if [ "$ENABLE_DEBUG" == "true" ]; then
        DEBUG_FLAG=-d
    fi

    # create a zone and exercise all script params
    create-pdns-zone.sh $DEBUG_FLAG -C "$PDNS_CONF_DIR/pdns.conf" -H $HOSTMASTER_EMAIL -t $TTL -r $REFRESH \
        -R $RETRY -e $EXPIRY -n $NEG_TTL -N $NS_TTL $ZONE_NAME $PRIMARY_MASTER $MASTER_2 $MASTER_3

    # dig ... AXFR prints SOA records on the first and last line by design
    local DIG_OUT="$($TEST_DIG +onesoa $ZONE_NAME AXFR)"
    if [ "$DIG_OUT" == "; Transfer failed." ]; then
        >&2 echo "testCreateAndDeleteZone '$TEST_DIG +onesoa $ZONE_NAME AXFR' failed."
        >&2 echo "pdns_server STDOUT:"
        >&2 cat "$PDNS_STDOUT"
        >&2 echo "pdns_server STDERR:"
        >&2 cat "$PDNS_STDERR"
        fail
    else
        local DIG_ZONE_NAME
        local DIG_HOSTMASTER_EMAIL
        local DIG_TTL
        local DIG_REFRESH
        local DIG_RETRY
        local DIG_EXPIRY
        local DIG_NEG_TTL
        local DIG_PRIMARY_MASTER_TTL
        local DIG_MASTER_2_TTL
        local DIG_MASTER_3_TTL

        eval $(echo "$DIG_OUT" | awk '
            /\tSOA\t/{
                print "DIG_ZONE_NAME="$1;
                print "DIG_TTL="$2;
                print "DIG_PRIMARY_MASTER="$5;
                sub(/\./, "@", $6);
                print "DIG_HOSTMASTER_EMAIL="$6
                print "DIG_REFRESH="$8;
                print "DIG_RETRY="$9;
                print "DIG_EXPIRY="$10;
                print "DIG_NEG_TTL="$11;
            }
            /\tNS\t'"$PRIMARY_MASTER"'$/{
                print "DIG_PRIMARY_MASTER_TTL="$2;
            }
            /\tNS\t'"$MASTER_2"'$/{
                print "DIG_MASTER_2_TTL="$2
            }
            /\tNS\t'"$MASTER_3"'$/{
                print "DIG_MASTER_3_TTL="$2
            }
        ')

        assertEquals 'Zone name' "$ZONE_NAME" "$DIG_ZONE_NAME"
        assertEquals 'Hostmaster email' "$HOSTMASTER_EMAIL" "$DIG_HOSTMASTER_EMAIL"
        assertEquals 'Zone TTL' "$TTL" "$DIG_TTL"
        assertEquals 'Zone referesh interval' "$REFRESH" "$DIG_REFRESH"
        assertEquals 'Zone retry interval' "$RETRY" "$DIG_RETRY"
        assertEquals 'Zone expiry time' "$EXPIRY" "$DIG_EXPIRY"
        assertEquals 'Zone NXDOMAIN TTL' "$NEG_TTL" "$DIG_NEG_TTL"
        assertEquals 'Primary NS record TTL' "$NS_TTL" "$DIG_PRIMARY_MASTER_TTL"
        assertEquals 'Secondary NS record TTL' "$NS_TTL" "$DIG_MASTER_2_TTL"
        assertEquals 'Tertiary NS record TTL' "$NS_TTL" "$DIG_MASTER_3_TTL"
    fi

    # delete zone
    delete-pdns-zone.sh $DEBUG_FLAG -C "$PDNS_CONF_DIR/pdns.conf" $ZONE_NAME

    # assert that zone was deleted
    assertEquals "Failed to delete test zone. " "; Transfer failed." "$($TEST_DIG +onesoa $ZONE_NAME AXFR)"
}

testCreateAndDeleteZoneWithDefaults(){
    local ZONE_NAME=$(_random_alphanumeric_chars 3).$(_random_alphanumeric_chars 3).tld.
    local PRIMARY_MASTER=primary.master.$ZONE_NAME
    local MASTER_2=secondary.master.$ZONE_NAME
    local MASTER_3=tertiary.master.$ZONE_NAME
    local HOSTMASTER_EMAIL=$(whoami)@$(hostname -s).corp.appdynamics.com.
    local TTL=86400
    local REFRESH=1200
    local RETRY=180
    local EXPIRY=1209600
    local NEG_TTL=60
    local NS_TTL=1209600
    local DEBUG_FLAG

    if [ "$ENABLE_DEBUG" == "true" ]; then
        DEBUG_FLAG=-d
    fi

    # create a zone and exercise all script params
    create-pdns-zone.sh $DEBUG_FLAG -C "$PDNS_CONF_DIR/pdns.conf" $ZONE_NAME $PRIMARY_MASTER $MASTER_2 $MASTER_3

    # dig ... AXFR prints SOA records on the first and last line by design
    local DIG_OUT="$($TEST_DIG +onesoa $ZONE_NAME AXFR)"
    if [ "$DIG_OUT" == "; Transfer failed." ]; then
        >&2 echo "testCreateAndDeleteZoneWithDefaults '$TEST_DIG +onesoa $ZONE_NAME AXFR' failed."
        >&2 echo "pdns_server STDOUT:"
        >&2 cat "$PDNS_STDOUT"
        >&2 echo "pdns_server STDERR:"
        >&2 cat "$PDNS_STDERR"
        fail
    else
        local DIG_ZONE_NAME
        local DIG_HOSTMASTER_EMAIL
        local DIG_TTL
        local DIG_REFRESH
        local DIG_RETRY
        local DIG_EXPIRY
        local DIG_NEG_TTL
        local DIG_PRIMARY_MASTER_TTL
        local DIG_MASTER_2_TTL
        local DIG_MASTER_3_TTL

        eval $(echo "$DIG_OUT" | awk '
            /\tSOA\t/{
                print "DIG_ZONE_NAME="$1;
                print "DIG_TTL="$2;
                print "DIG_PRIMARY_MASTER="$5;
                sub(/\./, "@", $6);
                print "DIG_HOSTMASTER_EMAIL="$6
                print "DIG_REFRESH="$8;
                print "DIG_RETRY="$9;
                print "DIG_EXPIRY="$10;
                print "DIG_NEG_TTL="$11;
            }
            /\tNS\t'"$PRIMARY_MASTER"'$/{
                print "DIG_PRIMARY_MASTER_TTL="$2;
            }
            /\tNS\t'"$MASTER_2"'$/{
                print "DIG_MASTER_2_TTL="$2
            }
            /\tNS\t'"$MASTER_3"'$/{
                print "DIG_MASTER_3_TTL="$2
            }
        ')

        assertEquals 'Zone name' "$ZONE_NAME" "$DIG_ZONE_NAME"
        assertEquals 'Hostmaster email' "$HOSTMASTER_EMAIL" "$DIG_HOSTMASTER_EMAIL"
        assertEquals 'Zone TTL' "$TTL" "$DIG_TTL"
        assertEquals 'Zone referesh interval' "$REFRESH" "$DIG_REFRESH"
        assertEquals 'Zone retry interval' "$RETRY" "$DIG_RETRY"
        assertEquals 'Zone expiry time' "$EXPIRY" "$DIG_EXPIRY"
        assertEquals 'Zone NXDOMAIN TTL' "$NEG_TTL" "$DIG_NEG_TTL"
        assertEquals 'Primary NS record TTL' "$NS_TTL" "$DIG_PRIMARY_MASTER_TTL"
        assertEquals 'Secondary NS record TTL' "$NS_TTL" "$DIG_MASTER_2_TTL"
        assertEquals 'Tertiary NS record TTL' "$NS_TTL" "$DIG_MASTER_3_TTL"
    fi

    # delete zone
    delete-pdns-zone.sh $DEBUG_FLAG -C "$PDNS_CONF_DIR/pdns.conf" $ZONE_NAME

    #assert that zone was deleted
    assertEquals "Failed to delete test zone. " "; Transfer failed." "$($TEST_DIG +onesoa $ZONE_NAME AXFR)"
}
