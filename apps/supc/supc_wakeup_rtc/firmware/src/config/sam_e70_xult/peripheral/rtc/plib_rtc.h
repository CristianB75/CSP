/*******************************************************************************
  Interface definition of RTC PLIB.

  Company:
    Microchip Technology Inc.

  File Name:
    plib_rtc.h

  Summary:
    Interface definition of the Real Time Counter Plib (RTC).

  Description:
    This file defines the interface for the RTC Plib.
    It allows user to setup alarm duration and access current date and time.
*******************************************************************************/

/*******************************************************************************
Copyright (c) 2016 released Microchip Technology Inc.  All rights reserved.

Microchip licenses to you the right to use, modify, copy and distribute
Software only when embedded on a Microchip microcontroller or digital signal
controller that is integrated into your product or third party product
(pursuant to the sublicense terms in the accompanying license agreement).

You should refer to the license agreement accompanying this Software for
additional information regarding your rights and obligations.

SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF
MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE.
IN NO EVENT SHALL MICROCHIP OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER
CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR
OTHER LEGAL EQUITABLE THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES
INCLUDING BUT NOT LIMITED TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR
CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF PROCUREMENT OF
SUBSTITUTE GOODS, TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES
(INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
*******************************************************************************/

#ifndef RTC_H    // Guards against multiple inclusion
#define RTC_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <time.h>
#include "plib_rtc_common.h"

#ifdef __cplusplus // Provide C++ Compatibility
 extern "C" {
#endif


// *****************************************************************************
// *****************************************************************************
// Section: Interface
// *****************************************************************************
// *****************************************************************************

/***************************** RTC API *******************************/
void RTC_Initialize( void );
bool RTC_TimeSet( struct tm *Time );
void RTC_TimeGet( struct tm *Time );
bool RTC_AlarmSet( struct tm *alarmTime, RTC_ALARM_MASK mask );
void RTC_CallbackRegister( RTC_CALLBACK callback, uintptr_t context );
void RTC_InterruptDisable(RTC_INT_MASK interrupt);
void RTC_InterruptEnable(RTC_INT_MASK interrupt);
	
#ifdef __cplusplus // Provide C++ Compatibility
 }
#endif

#endif
