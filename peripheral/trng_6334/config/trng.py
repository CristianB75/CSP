#Function for initiating the UI
def instantiateComponent(trngComponent):

	num = trngComponent.getID()[-1:]
	print("Running TRNG" + str(num))

	trngReserved = trngComponent.createBooleanSymbol("TRNG_Reserved", None)
	trngReserved.setLabel("TRNG Reserved")
	trngReserved.setVisible(False)

	trngWarning = trngComponent.createCommentSymbol("TRNG_COMMENT", None)
	trngWarning.setLabel("**** Warning: This module is used and configured by Crypto Library ****")
	trngWarning.setDependencies(showWarning, ["TRNG_Reserved"])
	trngWarning.setVisible(False)
	
	#Create the top menu
	trngMenu = trngComponent.createMenuSymbol(None, None)
	trngMenu.setLabel("Hardware Settings ")
	trngMenu.setDependencies(showMenu, ["TRNG_Reserved"])

	#Create a Checkbox to enable disable interrupts
	trngInterrupt = trngComponent.createBooleanSymbol("trngEnableInterrupt", trngMenu)
	print(trngInterrupt)
	trngInterrupt.setLabel("Enable Interrupts")
	trngInterrupt.setDefaultValue(False)
	
	trngIndex = trngComponent.createIntegerSymbol("INDEX", trngMenu)
	trngIndex.setVisible(False)
	trngIndex.setDefaultValue(int(num))

	
	#Generate Output Header
	trngHeaderFile = trngComponent.createFileSymbol(None, None)
	trngHeaderFile.setSourcePath("../peripheral/trng_6334/templates/plib_trng.h.ftl")
	trngHeaderFile.setMarkup(True)
	trngHeaderFile.setOutputName("plib_trng" + str(num) + ".h")
	trngHeaderFile.setMarkup(True)
	trngHeaderFile.setOverwrite(True)
	trngHeaderFile.setDestPath("peripheral/trng/")
	trngHeaderFile.setProjectPath("peripheral/trng/")
	trngHeaderFile.setType("HEADER")
	#Generate Output source
	
	trngSourceFile = trngComponent.createFileSymbol(None, None)
	trngSourceFile.setSourcePath("../peripheral/trng_6334/templates/plib_trng.c.ftl")
	trngSourceFile.setMarkup(True)
	trngSourceFile.setOutputName("plib_trng" + str(num) + ".c")
	trngSourceFile.setMarkup(True)
	trngSourceFile.setOverwrite(True)
	trngSourceFile.setDestPath("peripheral/trng/")
	trngSourceFile.setProjectPath("peripheral/trng/")
	trngSourceFile.setType("SOURCE")

def showWarning(trngWarning, trngReserved):
	trngWarning.setVisible(trngReserved.getValue())

def showMenu(trngMenu, trngReserved):
	trngMenu.setVisible(not trngReserved.getValue())
