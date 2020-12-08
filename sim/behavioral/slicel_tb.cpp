#include <stdio.h>
#include "slicel.h"

/* This file defines an example slicel test. The relevant classes are defined slicel.h 
 * Any file writing tests for a slicel must define. Note that both SlicelTest and SlicelDut have get_time() functions;
 *      double sc_time_stamp()
 */

SliceTest *test;
double sc_time_stamp() {
    return test->get_time();
}

void test_lut_directed() {
    int addrs[] = {0x51, 0x29, 0xF2, 0x7C, 0x1B, 0x76, 0x33, 0x66, 0x31, 0x25};
    for (int i=0; i<10; ++i) {
        printf("%d ", luts::s44_lookup(0x66334873, addrs[i]));
    }
}

void test_slicel_directed(int argc, char** argv, char** env, int mode, int seed, int iterations, int verbosity) {
    test = new SliceTest("slicel", mode, verbosity, seed);
    test->config_args(argc, argv, env);
    if (test->generate_config(mode))      printf("Failed to configure\b");
    if (test->run_test(mode, iterations)) printf("Test failed");
    delete test;
}

void test_slicel_crand(int argc, char** argv, char** env, int mode, int seed, int configs, int iterations, int verbosity) {
    int state, failed = 0, skipped = 0;
    int cc = 0, m7 = 0, m8 = 0;
    int soft[4] = {};
    char name[80];

    for (int i=0; i < configs; ++i) {
        sprintf(name, "slicel RAND (%d)", i);
        test = new SliceTest(name, mode, verbosity, seed++);
        test->config_args(argc, argv, env);
        state = test->generate_config(mode);
        if (state) {
            printf("Failed to configure (%d), skipping...\n", state);
            skipped += 1; 
        } else {
            test->config_coverage(cc, m7, m8, soft);
            failed += test->run_test(mode, iterations);
        }
        delete test;
    }

    printf("\n ================================================================================ \n");
    printf(" ============================    OVERALL SUMMARY     ============================ \n");
    printf("Skipped Tests: %d/%d\n", skipped, configs);
    printf("Failed Tests: %d/%d\n", failed , configs);
    printf("Config Coverage: \n carry_chain: %d\n mux7: %d\n mux8: %d\n soft_luts: [%d, %d, %d, %d]\n", 
            cc, m7, m8, soft[3], soft[2], soft[1], soft[0]);
}


int main(int argc, char** argv, char** env) {
    // TEST EXAMPLE                       mode, seed, cfgs, iter, verb
  //test_slicel_directed(argc, argv, env, RAND, 145 ,       200 , 100 ); // Directed Test
    test_slicel_crand   (argc, argv, env, RAND, 145 ,  10 , 100 , 100 ); // Constrained Random Test

    exit(0);
}

