# Exit statuses:
#
# 0 - No errors found.
# 1 - Build or test failure. Errors will be logged automatically.
# 2 - Untestable target. Retry with the "build" action.

BEGIN {
    status = 0;
}

{
    print;
    fflush(stdout);
}

/A build only device cannot be used to run this target/ {
    status = 1
}

END {
    fflush(stdout);
    exit status;
}
