#!perl

while(<>)
{
    my $TYPE;
    my $IN, $OUT;
    my $SMAC, $DMAC;
    my $SRC, $DST, $PROTO;
    my $LEN, $TOS, $SPT, $DPT, $FLAGS;

    my $TIME;

    s/(\d{2}:\d{2}:\d{2})/$TIME = $1, ""/e;

    s/DROP\[([^\]]+)\]/$TYPE = "DROP:$1", ""/e;
    s/drop\[([^\]]+)\]/$TYPE = "drop:$1", ""/e;
    s/FWRD\[([^\]]+)\]/$TYPE = "FWRD:$1", ""/e;

    s/IN=([^ ]+)/$IN = $1, ""/e;
    s/OUT=([^ ]+)/$OUT = $1, ""/e;

    s/MAC=((?:\w{2}:){6})((?:\w{2}:){6})\w{2}:\w{2}/$SMAC = $1, $DMAC = $2, ""/e;

    s/SRC=([^ ]+)/$SRC = $1, ""/e;
    s/DST=([^ ]+)/$DST = $1, ""/e;

    s/PROTO=([^ ]+)/$PROTO = $1, ""/e;

    s/LEN=([^ ]+)/$LEN = $1, ""/e;
    s/TOS=([^ ]+)/$TOS = $1, ""/e;
    s/SPT=([^ ]+)/$SPT = $1, ""/e;
    s/DPT=([^ ]+)/$DPT = $1, ""/e;

    if($TYPE){
        printf "%s %s %4s>%4s %15s>%15s %4s %5s>%5s len%5s tos%4s",
            $TIME, $TYPE, $IN, $OUT, $SRC, $DST, $PROTO, $SPT, $DPT, $LEN, $TOS;
        if($SMAC){
            printf "  MAC: %s>%s", $SMAC, $DMAC;
        }
        printf "\n";
    }
}
