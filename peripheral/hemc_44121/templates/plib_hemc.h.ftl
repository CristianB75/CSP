/*******************************************************************
  Company:
    Microchip Technology Inc.

  File Name:
    plib_${HEMC_INSTANCE_NAME?lower_case}.h

  Summary:
    HEMC PLIB Header File

  Description:
    None
*******************************************************************************/

/*******************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*******************************************************************************/
#ifndef PLIB_${HEMC_INSTANCE_NAME}_H
#define PLIB_${HEMC_INSTANCE_NAME}_H

#include <stdbool.h>

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    extern "C" {

#endif
// DOM-IGNORE-END

// *****************************************************************************
// *****************************************************************************
// Section: Include Files
// *****************************************************************************
// *****************************************************************************

// *****************************************************************************
// *****************************************************************************
// Section: Data Types
// *****************************************************************************
// *****************************************************************************
/* HEMC HECC channel
   Summary:
    Identifies the HEMC HECC channel

   Description:
    This data type identifies the HEMC HECC channel
*/
typedef enum
{
    HEMC_HEMC_CH_HSMC = 0,    /* HECC Channel for HSMC memories */
<#if USE_HSDRAM??>
    HEMC_HEMC_CH_HSDRAMC = 1  /* HECC Channel for HSDRAMC memories */
</#if>
} HEMC_HEMC_CHANNEL;

// *****************************************************************************
/* HEMC HECC status
   Summary:
    Identifies the HEMC HECC current status

   Description:
    This data type identifies the HEMC HECC status
*/

#define    HEMC_HECC_STATUS_MEM_FIX  HEMC_HECC_SR_MEM_FIX_Msk
#define    HEMC_HECC_STATUS_CPT_FIX_MASK   HEMC_HECC_SR_CPT_FIX_Msk
#define    HEMC_HECC_STATUS_OVER_FIX   HEMC_HECC_SR_OVER_FIX_Msk
#define    HEMC_HECC_STATUS_MEM_NOFIX   HEMC_HECC_SR_MEM_NOFIX_Msk
#define    HEMC_HECC_STATUS_CPT_NOFIX_MASK   HEMC_HECC_SR_CPT_NOFIX_Msk
#define    HEMC_HECC_STATUS_OVER_NOFIX   HEMC_HECC_SR_OVER_NOFIX_Msk
#define    HEMC_HECC_STATUS_HES_MASK   HEMC_HECC_SR_HES_Msk
#define    HEMC_HECC_STATUS_TYPE   HEMC_HECC_SR_TYPE_Msk
/* Force the compiler to reserve 32-bit memory for enum */
#define    HEMC_HECC_STATUS_INVALID   0xFFFFFFFFU

typedef uint32_t HEMC_HECC_STATUS;

// *****************************************************************************

/* HEMC Callback

   Summary:
    HEMC Callback Function Pointer.

   Description:
    This data type defines the HEMC Callback Function Pointer.

   Remarks:
    None.
*/
typedef void (*HEMC_CALLBACK) (uintptr_t contextHandle);

// *****************************************************************************

/* HEMC PLib Instance Object

   Summary:
    HEMC PLib Object structure.

   Description:
    This data structure defines the HEMC PLib Instance Object.

   Remarks:
    None.
*/
typedef struct
{
    /* Transfer Event Callback for Fixable Error interrupt*/
    HEMC_CALLBACK fix_callback;

    /* Transfer Event Callback Context for Fixable Error interrupt*/
    uintptr_t fix_context;

    /* Transfer Event Callback for NoFixable Error interrupt*/
    HEMC_CALLBACK nofix_callback;

    /* Transfer Event Callback Context for NoFixable Error interrupt*/
    uintptr_t nofix_context;
} HEMC_OBJ;

// *****************************************************************************
// *****************************************************************************
// Section: Interface Routines
// *****************************************************************************
// *****************************************************************************
<#if USE_HSDRAM?? && USE_HSDRAM>
void ${HSDRAMC_INSTANCE_NAME}_Initialize( void );
</#if>

void ${HEMC_INSTANCE_NAME}_Initialize( void );

bool ${HEMC_INSTANCE_NAME}_DisableECC(uint8_t chipSelect);

bool ${HEMC_INSTANCE_NAME}_EnableECC(uint8_t chipSelect);

HEMC_HECC_STATUS ${HEMC_INSTANCE_NAME}_HeccGetStatus(void);

uint32_t* ${HEMC_INSTANCE_NAME}_HeccGetFailAddress(void);

<#if HEMC_HECC_HAS_FAIL_DATA == true >
uint32_t ${HEMC_INSTANCE_NAME}_HeccGetFailData(void);

</#if>
void ${HEMC_INSTANCE_NAME}_HeccResetCounters(void);

<#if HECC_INTERRUPT_MODE == true>

void ${HEMC_INSTANCE_NAME}_FixCallbackRegister(HEMC_CALLBACK callback, uintptr_t contextHandle);

void ${HEMC_INSTANCE_NAME}_NoFixCallbackRegister(HEMC_CALLBACK callback, uintptr_t contextHandle);

</#if>

<#if HECC_INJECTION_TEST_MODE == true>
// *****************************************************************************
// *****************************************************************************
// Section: Interface Inlined TestMode Routines
// *****************************************************************************
// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_TestModeReadEnable(HEMC_HEMC_CHANNEL channel)

   Summary:
    Enable the ${HEMC_INSTANCE_NAME} peripheral HECC test mode Read. When enabled the
    ECC check bit value read is updated in TESTCB1 register at each HEMC data read.

   Precondition:
    None.

   Parameters:
    channel - HECC channel for the memory type.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_TestModeReadEnable(HEMC_HEMC_CHANNEL channel)
{
<#if HEMC_HECC_CR0_REG == false>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR |= HEMC_HECC_CR_TEST_MODE_RD_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR & HEMC_HECC_CR_TEST_MODE_RD_Msk) != HEMC_HECC_CR_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR0 |= HEMC_HECC_CR0_TEST_MODE_RD_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR0 & HEMC_HECC_CR0_TEST_MODE_RD_Msk) != HEMC_HECC_CR0_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
    else
    {
        HEMC_REGS->HEMC_HECC_CR1 |= HEMC_HECC_CR1_TEST_MODE_RD_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR1 & HEMC_HECC_CR1_TEST_MODE_RD_Msk) != HEMC_HECC_CR1_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }

        HEMC_REGS->HEMC_HECC_CR2 |= HEMC_HECC_CR2_TEST_MODE_RD_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR2 & HEMC_HECC_CR2_TEST_MODE_RD_Msk) != HEMC_HECC_CR2_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
</#if>
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_TestModeReadDisable(HEMC_HEMC_CHANNEL channel)

   Summary:
    Disable the ${HEMC_INSTANCE_NAME} peripheral HECC test mode Read.

   Precondition:
    None.

   Parameters:
    channel - HECC channel for the memory type.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_TestModeReadDisable(HEMC_HEMC_CHANNEL channel)
{
<#if HEMC_HECC_CR0_REG == false>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR &= ~(HEMC_HECC_CR_TEST_MODE_RD_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR & HEMC_HECC_CR_TEST_MODE_RD_Msk) == HEMC_HECC_CR_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR0 &= ~(HEMC_HECC_CR0_TEST_MODE_RD_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR0 & HEMC_HECC_CR0_TEST_MODE_RD_Msk) == HEMC_HECC_CR0_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
    else
    {
        HEMC_REGS->HEMC_HECC_CR1 &= ~(HEMC_HECC_CR1_TEST_MODE_RD_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR1 & HEMC_HECC_CR1_TEST_MODE_RD_Msk) == HEMC_HECC_CR1_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }

        HEMC_REGS->HEMC_HECC_CR2 &= ~(HEMC_HECC_CR2_TEST_MODE_RD_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR2 & HEMC_HECC_CR2_TEST_MODE_RD_Msk) == HEMC_HECC_CR2_TEST_MODE_RD_Msk )
        {
            /* Wait for register field update */
        }
    }
</#if>
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_TestModeWriteEnable(HEMC_HEMC_CHANNEL channel)

   Summary:
    Enable the ${HEMC_INSTANCE_NAME} peripheral HECC test mode Write. When enabled the
    ECC check bit value in TESTCB1 register is write in memory at each HEMC data write
    instead of calculated check bit.

   Precondition:
    None.

   Parameters:
    channel - HECC channel for the memory type.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_TestModeWriteEnable(HEMC_HEMC_CHANNEL channel)
{
<#if HEMC_HECC_CR0_REG == false>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR |= HEMC_HECC_CR_TEST_MODE_WR_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR & HEMC_HECC_CR_TEST_MODE_WR_Msk) != HEMC_HECC_CR_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR0 |= HEMC_HECC_CR0_TEST_MODE_WR_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR0 & HEMC_HECC_CR0_TEST_MODE_WR_Msk) != HEMC_HECC_CR0_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
    else
    {
        HEMC_REGS->HEMC_HECC_CR1 |= HEMC_HECC_CR1_TEST_MODE_WR_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR1 & HEMC_HECC_CR1_TEST_MODE_WR_Msk) != HEMC_HECC_CR1_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }

        HEMC_REGS->HEMC_HECC_CR2 |= HEMC_HECC_CR2_TEST_MODE_WR_Msk;
        while ( (HEMC_REGS->HEMC_HECC_CR2 & HEMC_HECC_CR2_TEST_MODE_WR_Msk) != HEMC_HECC_CR2_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
</#if>
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_TestModeWriteDisable(HEMC_HEMC_CHANNEL channel)

   Summary:
    Disable the ${HEMC_INSTANCE_NAME} peripheral HECC test mode Write.

   Precondition:
    None.

   Parameters:
    channel - HECC channel for the memory type.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_TestModeWriteDisable(HEMC_HEMC_CHANNEL channel)
{
<#if HEMC_HECC_CR0_REG == false>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR &= ~(HEMC_HECC_CR_TEST_MODE_WR_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR & HEMC_HECC_CR_TEST_MODE_WR_Msk) == HEMC_HECC_CR_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_CR0 &= ~(HEMC_HECC_CR0_TEST_MODE_WR_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR0 & HEMC_HECC_CR0_TEST_MODE_WR_Msk) == HEMC_HECC_CR0_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
    else
    {
        HEMC_REGS->HEMC_HECC_CR1 &= ~(HEMC_HECC_CR1_TEST_MODE_WR_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR1 & HEMC_HECC_CR1_TEST_MODE_WR_Msk) == HEMC_HECC_CR1_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }

        HEMC_REGS->HEMC_HECC_CR2 &= ~(HEMC_HECC_CR2_TEST_MODE_WR_Msk);
        while ( (HEMC_REGS->HEMC_HECC_CR2 & HEMC_HECC_CR2_TEST_MODE_WR_Msk) == HEMC_HECC_CR2_TEST_MODE_WR_Msk )
        {
            /* Wait for register field update */
        }
    }
</#if>
}

// *****************************************************************************
/* Function:
    uint16_t ${HEMC_INSTANCE_NAME}_TestModeGetCbValue(HEMC_HEMC_CHANNEL channel)

   Summary:
    Get the ${HEMC_INSTANCE_NAME} peripheral HECC test mode check bit values.

   Precondition:
    None.

   Parameters:
     channel - HECC channel for the memory type.

   Returns:
    Test check bit value.
*/
static inline uint16_t ${HEMC_INSTANCE_NAME}_TestModeGetCbValue(HEMC_HEMC_CHANNEL channel)
{
<#if HEMC_HECC_CR0_REG == false>
    return (uint16_t)(HEMC_REGS->HEMC_HECC_TESTCB & HEMC_HECC_TESTCB_TCB1_Msk);
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        return (uint16_t)(HEMC_REGS->HEMC_HECC_TESTCB0 & HEMC_HECC_TESTCB0_TCB1_Msk);
    }
    else
    {
        return (uint16_t)(HEMC_REGS->HEMC_HECC_TESTCB1 & HEMC_HECC_TESTCB1_TCB1_Msk);
    }
</#if>
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_TestModeSetCbValue(HEMC_HEMC_CHANNEL channel, uint16_t tcb1)

   Summary:
    Set the ${HEMC_INSTANCE_NAME} peripheral HECC test mode check bit values.

   Precondition:
    None.

   Parameters:
    channel - HECC channel for the memory type.
    tcb1 - Test check bit value to set.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_TestModeSetCbValue(HEMC_HEMC_CHANNEL channel, uint16_t tcb1)
{
<#if HEMC_HECC_CR0_REG == false>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_TESTCB = HEMC_HECC_TESTCB_TCB1(tcb1);
    }
<#else>
    if (channel == HEMC_HEMC_CH_HSMC)
    {
        HEMC_REGS->HEMC_HECC_TESTCB0 = HEMC_HECC_TESTCB0_TCB1(tcb1);
    }
    else
    {
        HEMC_REGS->HEMC_HECC_TESTCB1 = HEMC_HECC_TESTCB1_TCB1(tcb1);
        HEMC_REGS->HEMC_HECC_TESTCB2 = HEMC_HECC_TESTCB2_TCB1(tcb1);
    }
</#if>
}
</#if>

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Write8(uint32_t dataAddress, uint8_t data)

   Summary:
    Writes 8 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.
    data - data written.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_Write8(uint32_t dataAddress, uint8_t data)
{
    *((volatile uint8_t *)dataAddress) = data;
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Write16(uint32_t dataAddress, uint16_t data)

   Summary:
    Writes 16 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.
    data - data written.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_Write16(uint32_t dataAddress, uint16_t data)
{
    *((volatile uint16_t *)dataAddress) = data;
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Write32(uint32_t dataAddress, uint32_t data)

   Summary:
    Writes 32 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.
    data - data written.

   Returns:
    None
*/
static inline void ${HEMC_INSTANCE_NAME}_Write32(uint32_t dataAddress, uint32_t data)
{
    *((volatile uint32_t *)dataAddress) = data;
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Read8(uint32_t dataAddress)

   Summary:
    Read 8 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.

   Returns:
    Read data.
*/
static inline uint8_t ${HEMC_INSTANCE_NAME}_Read8(uint32_t dataAddress)
{
    return *((volatile uint8_t *)dataAddress);
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Read16(uint32_t dataAddress)

   Summary:
    Read 16 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.

   Returns:
    Read data.
*/
static inline uint16_t ${HEMC_INSTANCE_NAME}_Read16(uint32_t dataAddress)
{
    return *((volatile uint16_t *)dataAddress);
}

// *****************************************************************************
/* Function:
    void ${HEMC_INSTANCE_NAME}_Read32(uint32_t dataAddress)

   Summary:
    Read 32 bit data at given address.

   Precondition:
    None.

   Parameters:
    dataAddress - Address were data is written.

   Returns:
    Read data.
*/
static inline uint32_t ${HEMC_INSTANCE_NAME}_Read32(uint32_t dataAddress)
{
    return *((volatile uint32_t *)dataAddress);
}

// DOM-IGNORE-BEGIN
#ifdef __cplusplus  // Provide C++ Compatibility

    }

#endif
// DOM-IGNORE-END

#endif // PLIB_${HEMC_INSTANCE_NAME}_H
/*******************************************************************************
 End of File
*/
