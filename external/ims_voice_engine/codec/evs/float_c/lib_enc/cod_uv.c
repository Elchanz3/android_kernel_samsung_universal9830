/*====================================================================================
    EVS Codec 3GPP TS26.443 Oct 20, 2015. Version 12.4.0
  ====================================================================================*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include "prot.h"


/*-------------------------------------------------------------------*
 * gauss_L2:
 *
 * encode an additional Gaussian excitation for unvoiced subframes and compute
 * associated xcorrelations for gains computation
 *
 * Gaussian excitation is generated by a white noise and shapes it with LPC-derived filter
 *-------------------------------------------------------------------*/

void gauss_L2(
    const float h[],         /* i   : weighted LP filter impulse response    */
    float code[],            /* o   : gaussian excitation                    */
    float y2[],              /* i   : zero-memory filtered code. excitation  */
    float y11[],             /* o   : zero-memory filtered gauss. excitation */
    float *gain,             /* o   : excitation gain                        */
    float g_corr[],          /* i/o : correlation structure for gain coding  */
    float gain_pit,          /* i   : unquantized gain of code               */
    float tilt_code,         /* i   : tilt of code                           */
    const float *Aq,         /* i   : quantized LPCs                         */
    float formant_enh_num,   /* i   : formant enhancement factor             */
    short *seed_acelp        /*i/o  : random seed                            */
)
{
    short i;
    assert(gain_pit==0.f);
    (void)gain_pit;

    /*-----------------------------------------------------------------*
     * Find new target for the Gaussian codebook
     *-----------------------------------------------------------------*/

    /*Generate white gaussian noise using central limit theorem method (N only 4 as E_util_random is not purely uniform)*/
    for( i=0; i<L_SUBFR; i++ )
    {
        code[i]=(float)(own_random(seed_acelp))/(1<<15);
        code[i]+=(float)(own_random(seed_acelp))/(1<<15);
        code[i]+=(float)(own_random(seed_acelp))/(1<<15);
    }

    /*Shape the gaussian excitation*/
    cb_shape( 1, 0, 0, 1, 0, formant_enh_num, FORMANT_SHARPENING_G2, Aq, code, tilt_code, 0 );

    /*compute 0s memory weighted synthesis contribution and find gain*/
    conv( code, h, y11, L_SUBFR );
    *gain =0.f;

    /*Update correlations for gains coding */
    g_corr[0] = 0.01F + dotp( y11, y11, L_SUBFR );
    g_corr[4] = 0.01F + dotp( y11, y2, L_SUBFR );

    return;
}
