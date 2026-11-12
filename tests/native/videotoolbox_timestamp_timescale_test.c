#include <CoreMedia/CoreMedia.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct AVRational {
    int num;
    int den;
} AVRational;

extern int64_t av_rescale_q(int64_t value, AVRational source, AVRational destination);

static bool cm_time_to_packet_pts(CMTime time, AVRational packet_time_base, int64_t *pts)
{
    if (!CMTIME_IS_VALID(time) || time.timescale <= 0) {
        return false;
    }

    *pts = av_rescale_q(time.value, (AVRational){ 1, time.timescale }, packet_time_base);
    return true;
}

static void expect_pts(const char *case_name, CMTime time, int64_t expected)
{
    int64_t pts = 0;

    if (!cm_time_to_packet_pts(time, (AVRational){ 1, 30 }, &pts) || pts != expected) {
        fprintf(stderr, "%s: expected PTS %lld, got %lld\n",
                case_name, (long long)expected, (long long)pts);
        exit(EXIT_FAILURE);
    }
}

int main(void)
{
    int64_t pts;

    expect_pts("unchanged timescale", CMTimeMake(1, 30), 1);
    expect_pts("microsecond timescale", CMTimeMake(33333, 1000000), 1);

    if (cm_time_to_packet_pts(kCMTimeInvalid, (AVRational){ 1, 30 }, &pts)) {
        fputs("invalid PTS was accepted\n", stderr);
        return EXIT_FAILURE;
    }

    puts("VideoToolbox timestamp rescaling cases passed");
    return EXIT_SUCCESS;
}
