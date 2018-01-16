/*******************************************************************************
 Interface definition of EEFC PLIB.
 
 Company:
	Microchip Technology Inc.
	
 File Name:
	plib_EEFC.h
	
 Summary:
	Interface definition of EEFC Plib.
	
 Description:
	This file defines the interface for the EEFC Plib.
	It allows user to Program, Erase and lock the on-chip FLASH memory.
*******************************************************************************/

// DOM-IGNORE-BEGIN
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
// DOM-IGNORE-END

#ifndef EEFC_H    // Guards against multiple inclusion
#define EEFC_H

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************
/*  This section lists the other files that are included in this file.
*/
/* This section lists the other files that are included in this file.
*/

#include <xc.h>
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// DOM-IGNORE-BEGIN
#ifdef __cplusplus // Provide C++ Compatibility
	extern "C" {
#endif
// DOM-IGNORE-END

// *****************************************************************************
// *****************************************************************************
// Section: Data Types
// *****************************************************************************
// *****************************************************************************

/* EEFC STATUS
 Summary:
	Defines the data type for the EEFC STATUS.
	
 Description:
	This enum is used to define status of last Flash operation.
	
 Remarks:
	None.
*/

typedef enum
{
	/* FLASH operation completed successfully */
	EEFC_SUCCESS = 0x1,
	/*Flash Operation is not complete*/
	EEFC_BUSY,
	/* FLASH operation lead to an error */
	EEFC_ERROR
} EEFC_STATUS;

/* EEFC ERR
 Summary:
	Defines the data type for the EEFC Error.
	
 Description:
	This enum is used to define error encountered during last Flash operation.
	
 Remarks:
	None.
*/ 
typedef enum
{
	/*In-valid command*/
	EEFC_CMD_ERROR = 0x2,
	/*Flash region is locked*/
	EEFC_LOCK_ERROR = 0x4,
	/*Flash Error*/
	EEFC_FLERR_ERROR = 0x8,
	/*Flash Encountered an ECC error*/
	EEFC_ECC_ERROR = 0xF0000,
} EEFC_ERR;

// *****************************************************************************
// *****************************************************************************
/* Callback Function Pointer
 Summary:
	Defines the data type and function signature for the EEFC peripheral
	callback function.
	
 Description:
	This data type defines the function signature for the EEFC peripheral
	callback function. The EEFC peripheral will call back the client's
	function with this signature when the EEFC is ready to accept new operation.
	
 Precondition:
	EEFC_CallbackRegister must have been called to set the function to be called.
	
 Parameters:
	context - Allows the caller to provide a context value (usually a pointer
			to the callers context for multi-instance clients).
			
 Returns:
	None.
*/
typedef void (*EEFC_CALLBACK)(uintptr_t context);

// *****************************************************************************
// *****************************************************************************
// Section: Interface Routines
// *****************************************************************************
// *****************************************************************************
/* The following functions make up the methods (set of possible operations) of
this interface.
*/
// *****************************************************************************
/* Function:
	void EEFC_WriteQuadWord( uint32_t address, uint32_t* data )
	
 Summary:
	Writes a 128-bit data to a given address in FLASH memory.
	
 Description:
	This function takes a 32-bit address, a pointer to the 128-bit data and writes it to
	the given location in FLASH memory.
	
 Precondition:
	None
	
 Parameters:
	address:- FLASH address to be modified
	data   :- pointer to 128-bit data buffer  
	
 Returns:
	None.
	
 Example:
	<code>
		EEFC0_WriteQuadWord( 0x500000, &buffer);
		do 
		{
			status = EEFC0_StatusGet();
		} while (status != EEFC_SUCCESS);
	</code>
*/
void EEFCx_WriteQuadWord( uint32_t address, uint32_t* data );

/* Function:
	void EEFCx_WritePage( uint32_t address, uint32_t* data )
	
 Summary:
	Writes data of size equivalent to page size to a given FLASH address.
	
 Description:
	This function takes a 32-bit address, a pointer to data of size equivalent to page size
	and writes it to the given location in FLASH memory.
	
 Precondition:
	None.
	
 Parameters:
	address:- FLASH address to be modified
	data   :- pointer to data buffer  
	
 Returns:
	None.
	
 Example:
	<code>
		EEFC0_WritePage( 0x500000, &buffer);
		do 
		{
			status = EEFC0_StatusGet();
		} while (status != EEFC_SUCCESS);
	</code>
*/
void EEFCx_WritePage( uint32_t address, uint32_t* data );

/* Function:
	void EEFCx_EraseRow( uint32_t address)
	
 Summary:
	Erases a Row in the FLASH.
	
 Description:
	This function is used to erase a row (collection of pages).
	
 Precondition:
	None.
	
 Parameters:
	address:- FLASH address to be Erased  
	
 Returns:
	None.
	
 Example:
	<code>
		EEFC0_EraseRow( 0x500000 );
		do 
		{
			status = EEFC0_StatusGet();
		} while (status != EEFC_SUCCESS);		
	</code>
*/
void EEFCx_EraseRow( uint32_t address );

/* Function:
	uint32_t EEFCx_ErrorGet( void )
	
 Summary:
	Returns the error encountered by EEFC controller.
	
 Description:
	This function is used to check error encountered by EEFC controller.
	
 Precondition:
	None.
	
 Parameters:
	None
	
 Returns:
	uint32_t :- EEFC controller error type
	
 Example:
	<code>
		uint32_t error;
		if (EEFC0_StatusGet() == EEFC_ERROR)
		{
			error = EEFC0_ErrorGet();
		}
	</code>
*/

uint32_t EEFCx_ErrorGet( void );

/* Function:
	EEFC_Status EEFCx_StatusGet( void )
	
 Summary:
	Returns the current status of EEFC controller.
	
 Description:
	This function is used to check status of the last EEFC operation
	
 Precondition:
	None.
	
 Parameters:
	None
 Returns:
	EEFC_Status :- EEFC status for the last operation
	
 Example:
	<code>
		uint8_t status = EEFC0_StatusGet();
	</code>
*/

EEFC_STATUS EEFCx_StatusGet( void );

/* Function:
	void EEFCx_RegionLock(uint32_t address);
	
 Summary:
	Locks a Flash region.
	
 Description:
	This function is used to lock a certain region of on-chip flash.
	It takes in address as a parameter and locks the region associated with it. 
	
 Precondition:
	Validate if EEFC controller is ready to accept new request by calling EEFC_IsBusy()
	
 Parameters:
	address:- Address of the page to be locked 
	
 Returns:
	None.
	
 Example:
	<code>
		EEFC0_RegionLock(0x00500000);
		do 
		{
			status = EEFC0_StatusGet();
		} while (status != EEFC_SUCCESS);		
	</code>
*/

void EEFCx_RegionLock(uint32_t address);

/* Function:
	void EEFCx_RegionUnlock(uint32_t address);
	
 Summary:
	Unlocks a Flash region.
	
 Description:
	This function is used to Unlock a certain region of on-chip flash.
	It takes in address as a parameter and unlocks the region associated with it. 
	
 Precondition:
	Validate if EEFC controller is ready to accept new request by calling EEFC_IsBusy()
	
 Parameters:
	address:- Address of the page to be unlocked 
	
 Returns:
	None.
	
 Example:
	<code>
		EEFC0_RegionUnlock(0x00500000);
		do 
		{
			status = EEFC0_StatusGet();
		} while (status != EEFC_SUCCESS);
		}
	</code>
*/

void EEFCx_RegionUnlock(uint32_t address);

/* Function:
	void EEFCx_CallbackRegister( EEFC_CALLBACK callback, uintptr_t context )
	
 Summary:
	Sets the pointer to the function (and it's context) to be called when the
	operation is complete.
	
 Description:
	This function sets the pointer to a client function to be called "back"
	when the EEFC is ready to receive new command. It also passes a context value that is passed into the
	function when it is called.
	This function is available only in interrupt mode of operation.
	
 Precondition:
	None.
	
 Parameters:
	callback - A pointer to a function with a calling signature defined
				by the EEFC_CALLBACK data type.
	context - A value (usually a pointer) passed (unused) into the function
				identified by the callback parameter.
				
 Returns:
	None.
	
 Example:
	<code>
		EEFCx_CallbackRegister(MyCallback, &myData);
	</code>
	
 Remarks:
	The context value may be set to NULL if it is not required. Note that the
	value of NULL will still be passed to the callback function.
	To disable the callback function, pass a NULL for the callback parameter.
	See the EEFC_CALLBACK type definition for additional information.
*/

void EEFCx_CallbackRegister( EEFC_CALLBACK callback, uintptr_t context );

// DOM-IGNORE-BEGIN
#ifdef __cplusplus // Provide C++ Compatibility
}
#endif
// DOM-IGNORE-END
#endif