; IcnClipBrd
; Version 0.16
;
; Generated by Armalyser 0.44 (28-Mar-2003)
; 32-bit conversion and source tidying by Stephen Fryatt
;
; Assemble with AsAsm and pass through strip.
; Set file type of output file to &FFA

; ==========================================================================================================================================
; Constants

; SWI Names

	GET	$Include/SWINames

; Service Calls

Service_PostReset			EQU &27
Service_StartWimp			EQU &49
Service_StartedWimp			EQU &4A
Service_TerritoryStarted		EQU &75


; Wimp Messages

Message_DataSave			EQU 1
Message_DataSaveAck			EQU 2
Message_DataLoad			EQU 3
Message_DataLoadAck			EQU 4
Message_RAMFetch			EQU 6
Message_RAMTransmit			EQU 7
Message_ClaimEntity			EQU &F
Message_DataRequest			EQU &10
Message_Quit				EQU 0


; Key codes

Ctrl_C					EQU &43


; Workspace usage

					^	0
WS_TaskHandle				#	4
WS_PollBlockPtr				#	4
WS_PollWord				#	4
WS_ContentPtr				#	4
WS_ContentLen				#	4
WS_BytesSent				#	4
WS_FlagWord				#	4
WS_OtherTask				#	4
WS_PollBlock				#	288
WS_UCTable				#	4
WS_LCTable				#	4
WS_CPTable				#	4
WS_UPTable				#	8	; Old code allocated 8 bytes here?!
WS_Size					*	@


; Flag bits

F_Quote					EQU &000001

F_CtrlC					EQU &000100
F_CtrlD					EQU &000200
F_CtrlE					EQU &000400
F_CtrlK					EQU &000800
F_CtrlQ					EQU &001000
F_CtrlV					EQU &002000
F_CtrlX					EQU &004000
F_CtrlZ					EQU &008000
F_CtrlS					EQU &010000
F_CtrlT					EQU &020000


; The RAM Transfer Block is specified as an offset into the Wimp Poll Block.

WS_RAMBlockOffset			EQU &80
WS_RAMBlockSize				EQU &80

; ==========================================================================================================================================

	AREA	Module,CODE
	ENTRY

; ==========================================================================================================================================
; Module Header

ModuleHeader
	DCD	StartCode			; Start offset
	DCD	InitialisationCode		; Initialisation offset
	DCD	FinalisationCode		; Finalisation offset
	DCD	ServiceCallHandler		; Service call handler offset
	DCD	TitleString			; Title string offset
	DCD	HelpString			; Help string offset
	DCD	CommandTable			; Help and command keyword table offset
	DCD	0
	DCD	0
	DCD	0
	DCD	0
	DCD	0
	DCD	ModuleFlagWord

; ==========================================================================================================================================

ModuleFlagWord
	DCD	1

; ==========================================================================================================================================

CommandTable
	DCB 	"Desktop_IcnClipBrd",0
	ALIGN
	DCD	CommandCode_Desktop
	DCD	&00000000
	DCD	&00000000
	DCD	CommandDesktopHelp

	DCB	"IcnClipBrdKeys",0
	ALIGN
	DCD	CommandCode_Keys
	DCD	&00010000
	DCD	CommandKeysSyntax
	DCD	CommandKeysHelp

	DCD	0

; ==========================================================================================================================================
; Application Entry Point

StartCode
	LDR	R12,[R12]			; Initialise the workspace and stack.
	LDR	R13,[R12,#WS_PollBlockPtr]
	ADD	R13,R13,#&120

	LDR	R0,[R12,#WS_TaskHandle]		; Test the stored task handle to see if a task is
	CMP	R0,#0				; already running.
	BLE	StartNoTask

	LDR	R1,TaskWord			; If our task is already running, kill it.
	SWI	XWimp_CloseDown
	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]

StartNoTask
	MOV	R0,#&13,28			; Now our task isn't running, start it up again.
	ORR	R0,R0,#6
	LDR	R1,TaskWord
	ADRL	R2,TitleString
	ADR	R3,WimpInitialise_MessageList
	SWI	XWimp_Initialise
	SWIVS	OS_Exit
	STR	R1,[R12,#WS_TaskHandle]

WimpPollLoop
	MOV	R0,#&06,22			; Enter the Wimp_Poll loop.
	ORR	R0,R0,#&31
	ORR	R0,R0,#&01,10
	LDR	R1,[R12,#WS_PollBlockPtr]
	ADD	R3,R12,#WS_PollWord
	SWI	Wimp_Poll

	ADR	R14,WimpPollLoop
	CMP	R0,#&14
	ADDCC	PC,PC,R0,LSL #2
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollWordNonZero
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpPollLoop
	B	WimpMessageHandler
	B	WimpMessageHandler
	B	WimpMessageBounced

	SWI	OS_Exit

; ==========================================================================================================================================
; Poll Word Non-Zero Handler

WimpPollWordNonZero
	LDR	R2,[R12,#WS_PollWord]
	MOV	R0,#0
	STR	R0,[R12,#WS_PollWord]

	CMP	R2,#&43				; Ctrl-C
	CMPNE	R2,#&58				; Ctrl-X
	BEQ	WimpPollWord_CutCopy

	CMP	R2,#&56				; Ctrl-V
	BNE	WimpPollLoop

WimpPollWord_Paste
	MOV	R0,#Message_DataRequest		; Deal with paste requests, by sending a Message_DataRequest
	STR	R0,[R1,#16]			; to get the clipboard contents.
	MOV	R0,#48
	STR	R0,[R1,#0]
	MVN	R0,#0
	STR	R0,[R1,#20]
	STR	R2,[R1,#24]
	MOV	R0,#4
	STR	R0,[R1,#36]
	LDR	R0,Filetype
	STR	R0,[R1,#40]
	MVN	R0,#0
	STR	R0,[R1,#44]
	MOV	R2,#0
	STR	R2,[R1,#12]
	MOV	R0,#17
	SWI	XWimp_SendMessage
	B	WimpPollLoop

WimpPollWord_CutCopy				; Deal with cut or copy requests, by sending a Message_ClaimEntity
	MOV	R0,#Message_ClaimEntity		; to take the clipboard over.
	STR	R0,[R1,#16]
	MOV	R0,#4
	STR	R0,[R1,#20]
	MOV	R0,#24
	STR	R0,[R1,#0]
	MOV	R0,#0
	STR	R0,[R1,#12]
	MOV	R0,#17
	MOV	R2,#0
	SWI	XWimp_SendMessage
	B	WimpPollLoop

; ==========================================================================================================================================
; Wimp Message List

WimpInitialise_MessageList
	DCD	Message_DataSave
	DCD	Message_DataSaveAck
	DCD	Message_DataLoad
	DCD	Message_RAMFetch
	DCD	Message_RAMTransmit
	DCD	Message_ClaimEntity
	DCD	Message_DataRequest
	DCD	Message_Quit

; ==========================================================================================================================================
; Wimp Message Handler

WimpMessageHandler
	LDR	R0,[R1,#&010]

	CMP	R0,#Message_ClaimEntity
	BEQ	MessageHandlerClaimEntity

	CMP	R0,#Message_DataRequest
	BEQ	MessageHandlerDataRequest

	CMP	R0,#Message_DataSaveAck
	BEQ	MessageHandlerDataSaveAck

	CMP	R0,#Message_DataLoad
	BEQ	MessageHandlerDataLoad

	CMP	R0,#Message_DataSave
	BEQ	MessageHandlerDataSave

	CMP	R0,#Message_RAMFetch
	BEQ	MessageHandlerRAMFetch

	CMP	R0,#Message_RAMTransmit
	BEQ	MessageHandlerRAMTransmit

	CMP	R0,#Message_Quit
	BEQ	MessageQuit

	B	WimpPollLoop

; ==========================================================================================================================================
; We receive a Message_RAMFetch if another task is trying to get our clipboard data off us.  If we let it bounce, we should
; then receive a Message_DataSaveAck.

MessageHandlerRAMFetch
	LDR	R5,[R12,#WS_ContentPtr]		; Check that we own the clipboard before doing anything.
	CMP	R5,#0
	BEQ	WimpPollLoop

	LDR	R0,[R1,#8]			; Reply with Code 19???
	STR	R0,[R1,#12]
	MOV	R0,#19
	LDR	R2,[R1,#4]
	SWI	XWimp_SendMessage

	LDR	R0,[R12,#WS_ContentLen]		; Work out how many bytes are left to send.
	LDR	R6,[R12,#WS_BytesSent]
	SUB	R4,R0,R6

	LDR	R3,[R1,#20]			; Work out how many bytes will be sent (R4) and update the count in RMA.
	LDR	R0,[R1,#24]
	CMP	R0,R4
	MOVLT	R4,R0
	ADD	R0,R6,R4
	STR	R0,[R12,#WS_BytesSent]

	LDR	R0,[R12,#WS_TaskHandle]		; Call Wimp_TransferBlock to send the data.
	STR	R4,[R1,#24]
	ADD	R1,R5,R6
	SWI	XWimp_TransferBlock
	BLVS	ReportWimpError

	LDR	R1,[R12,#WS_PollBlockPtr]	; Send a Message_RAMTransmit to complete the process.
	MOV	R0,#Message_RAMTransmit		; *** This should send UserMessageRecorded if we fill the buffer.
	STR	R0,[R1,#16]
	MOV	R0,#17
	SWI	XWimp_SendMessage

	B	WimpPollLoop

; ==========================================================================================================================================
; We receive a Message_RAMTransmit if we are getting clipboard data off another task.

MessageHandlerRAMTransmit
	LDR	R2,[R1,#4]			; Reply with Code 19???
	LDR	R3,[R1,#8]
	STR	R3,[R1,#12]
	MOV	R0,#19
	SWI	XWimp_SendMessage

	LDR	R4,[R1,#24]			; R4 and R5 = the number of bytes transferred. R3 = the end of our buffer.
	MOV	R5,R4
	ADD	R3,R1,#WS_RAMBlockOffset

MessageHandlerRAMTransmitLoop
	SUBS	R4,R4,#1			; Start to loop, exiting when we have no data left in the buffer.
	BMI	MessageHandlerRAMTransmitLoopExit

	MOV	R0,#&8A				; Put the bytes received into the keyboard buffer.
	MOV	R1,#0
	LDRB	R6,[R3],#1
	CMP	R6,#0				; Exit on a zero terminator.  *** Should this be ctrl?
	BEQ	WimpPollLoop

	TST	R6,#&80                        	; Handle the special case of bytes >127.
	MOVNE	R2,#0
	SWINE	XOS_Byte

	MOV	R2,R6
	SWI	XOS_Byte
	BCS	WimpPollLoop

	B	MessageHandlerRAMTransmitLoop

MessageHandlerRAMTransmitLoopExit
	CMP	R5,#WS_RAMBlockSize		; If the block wasn't full, exit now...
	BLT	WimpPollLoop

	LDR	R1,[R12,#WS_PollBlockPtr]	; ...otherwise send another Message_RAMFetch to get the rest of the data.
	MOV	R0,#Message_RAMFetch
	STR	R0,[R1,#16]
	MOV	R0,#WS_RAMBlockSize
	STR	R0,[R1,#24]
	MOV	R0,#17
	LDR	R2,[R12,#WS_OtherTask]
	SWI	XWimp_SendMessage

	B	WimpPollLoop

; ==========================================================================================================================================
; Message_DataSave comes in as a response to our sending Message_DataRequest.

MessageHandlerDataSave
	LDR	R0,[R1,#40]			; Test the filetype that is offered.  If it isn't one we can handle,
	LDR	R2,Filetype			; beep and exit.
	CMP	R0,R2
	SWINE	OS_WriteI+7
	BNE	WimpPollLoop			; **** CAUTION: conditional after BL/SWI.

	MOV	R0,#19				; Reply with Code 19???
	LDR	R2,[R1,#4]
	LDR	R3,[R1,#8]
	STR	R3,[R1,#12]
	SWI	Wimp_SendMessage

	MOV	R0,#18				; Start to fill in a Message_RAMFetch.
	MOV	R3,#Message_RAMFetch		; This never seems to get called???
	STR	R3,[R1,#16]
	MOV	R3,#28
	STR	R3,[R1,#0]
	ADD	R3,R1,#WS_RAMBlockOffset
	STR	R3,[R1,#20]
	MOV	R3,#WS_RAMBlockSize
	STR	R3,[R1,#24]
	STR	R2,[R12,#WS_OtherTask]
;	B	WimpMessageBounced		; Comment out to enable RAM transfers

	SWI	Wimp_SendMessage
	B	WimpPollLoop

; ==========================================================================================================================================
; Bounced message handler - the only one we worry about is a bounced Message_RAMFetch, which starts the
; rest of the data transfer protocol off.

WimpMessageBounced
	LDR	R0,[R1,#16]			; Exit immediately if the bounced message isn't
	CMP	R0,#Message_RAMFetch		; Message_RAMFetch.
	BNE	WimpPollLoop

	MOV	R0,#60				; Start to assemble the block for Message_DataSaveAck
	STR	R0,[R1,#0]
	ADR	R0,WimpScrapString
	ADD	R2,R1,#44

CopyWimpScrapString
	LDRB	R3,[R0],#1
	STRB	R3,[R2],#1
	CMP	R3,#&20				; " "
	BGE	CopyWimpScrapString

	MVN	R0,#0				; -1 indicates that the file is 'unsafe'
	STR	R0,[R1,#36]
	MOV	R0,#Message_DataSaveAck
	STR	R0,[R1,#16]
	MOV	R0,#17
	LDR	R2,[R12,#WS_OtherTask]
	SWI	XWimp_SendMessage
	B	WimpPollLoop

; ------------------------------------------------------------------------------------------------------------------------------------------

WimpScrapString
	DCB	"<Wimp$Scrap>",0
	ALIGN

; ==========================================================================================================================================
; Message_DataLoad comes in response to our sending Message_DataSaveAck, and should indicate the the
; data is saved into Wimp$Scrap for us.

MessageHandlerDataLoad
	MOV	R0,#&4F				; Open the file containing the clipboard contents.
	ADD	R1,R1,#44
	SWI	XOS_Find
	BLVS	ReportWimpError
	BVS	WimpPollLoop

	MOV	R9,R0				; The file handle is now in R9.

DataLoadPasteLoop
	MOV	R1,R9				; Read a byte from the file, and end if fails.
	SWI	XOS_BGet
	BCS	DataLoadPasteLoopExit

	CMP	R0,#0				; End if the byte is zero.
	BEQ	DataLoadPasteLoopExit

	MOV	R3,R0				; Insert the byte into the keyboard buffer, prefixing
	TST	R3,#&80				; it with zero if it is >127.
	MOV	R0,#&8A
	MOV	R1,#0
	MOVNE	R2,#0
	SWINE	XOS_Byte
	MOV	R2,R3
	SWI	XOS_Byte
	BCS	DataLoadPasteLoopExit
	B	DataLoadPasteLoop

DataLoadPasteLoopExit
	MOV	R0,#0				; Close the scrap file.
	MOV	R1,R9
	SWI	XOS_Find

	LDR	R1,[R12,#WS_PollBlockPtr]	; Send a Message_DataLoadAck to finish the transfer.
	MOV	R0,#Message_DataLoadAck
	STR	R0,[R1,#16]
	LDR	R0,[R1,#8]
	STR	R0,[R1,#12]
	MOV	R0,#17
	LDR	R2,[R1,#4]
	SWI	XWimp_SendMessage

	ADD	R1,R1,#44			; Wipe the WimpScrap file following the transfer.
	MOV	R0,#27
	MOV	R3,#0
	SWI	XOS_FSControl

	B	WimpPollLoop

; ==========================================================================================================================================
; If we failed to respond to their Message_RAMFetch, the other task will now send us a Message_DataSaveAck to get the file saved.

MessageHandlerDataSaveAck
	LDR	R4,[R12,#WS_ContentPtr]		; Check that we have the clipboard, and exit if not.
	CMP	R4,#0
	BEQ	WimpPollLoop

	MOV	R0,#10				; Save the data to the file given in the message, using OS_File 10.
	ADD	R1,R1,#44
	MOV	R2,#&01,20			; =1<<12
	SUB	R2,R2,#1
	LDR	R5,[R12,#WS_ContentLen]
	ADD	R5,R5,R4
	SWI	XOS_File
	BLVS	ReportWimpError

	LDR	R1,[R12,#WS_PollBlockPtr]	; Send a Message_DataLoad to indicate that the file is in place.
	LDR	R0,[R1,#8]
	STR	R0,[R1,#12]
	MOV	R0,#Message_DataLoad
	STR	R0,[R1,#16]
	MOV	R0,#17
	LDR	R2,[R1,#4]
	SWI	XWimp_SendMessage

	B	WimpPollLoop

; ==========================================================================================================================================

ReportWimpError
	ORR	R14,R14,#&01,4			; =1<<28, CAUTION: manipulation of PSR in address?. Function entry, (preserves flags)
	STMFD	R13!,{R0-R2,R14}
	MOV	R1,#5
	SWI	XWimp_ReportError
	LDMFD	R13!,{R0-R2,PC}

; ==========================================================================================================================================
; Message_ClaimEntity
;
; Someone else has taken control of the clipboard.

MessageHandlerClaimEntity
	LDR	R0,[R1,#4]			; First check that we didn't send the message out.
	LDR	R2,[R12,#WS_TaskHandle]
	CMP	R0,R2
	BEQ	WimpPollLoop

	LDR	R0,[R1,#20]			; Check that it is the clipboard being claimed.
	TST	R0,#4
	BEQ	WimpPollLoop

	BL	FreeClipboardContents		; Release the memory used for the clipboard contents.
	B	WimpPollLoop

; ==========================================================================================================================================
; Message_DataRequest comes in to indicate that someone else wants a copy of the clipboard contents.

MessageHandlerDataRequest
	LDR	R0,[R12,#WS_ContentPtr]		; Check if we own the clipboard, and ignore the message if we don't.
	CMP	R0,#0
	BEQ	WimpPollLoop

	MOV	R0,#0				; Zero the bytes sent count before starting any RAM transfer.
	STR	R0,[R12,#WS_BytesSent]

	LDR	R0,[R1,#36]			; Check that it's a send clipboard request, and ignore it otherwise.
	TST	R0,#4
	BEQ	WimpPollLoop

	MOV	R0,#19				; Reply with code 19????
	LDR	R2,[R1,#4]			; *** Did LDR R5
;	MOV	R2,R5
	LDR	R3,[R1,#8]
	STR	R3,[R1,#12]
	SWI	XWimp_SendMessage

	MOV	R0,#56				; Start to fill in the block for Message_DataSave
	STR	R0,[R1,#0]
	LDR	R0,[R12,#WS_ContentLen]
	STR	R0,[R1,#36]
	ADD	R0,R1,#40
	ADR	R5,Filetype			; *** Did ADR R2
	ADR	R3,SuggestedFilenameEnd

MessageDataRequestCopyLoop
	LDRB	R4,[R5],#1			; Copy in the filetype and the proposed name for the file.  *** Did use [R2]
	STRB	R4,[R0],#1
	CMP	R5,R3				; *** Did CMP R2,R3
	BLT	MessageDataRequestCopyLoop

	MOV	R0,#Message_DataSave
	STR	R0,[R1,#16]
	MOV	R0,#17
;	MOV	R2,R5
	SWI	XWimp_SendMessage

	B	WimpPollLoop

; ------------------------------------------------------------------------------------------------------------------------------------------

Filetype
	DCD	&FFF
SuggestedFilename
	DCB	"IconText",0
SuggestedFilenameEnd
	ALIGN

; ==========================================================================================================================================
; Handle Message_Quit, buy shutting down the Wimp task and clearing the taskhandle.

MessageQuit
	LDR	R0,[R12,#WS_TaskHandle]
	LDR	R1,TaskWord
	SWI	XWimp_CloseDown

	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]

	SWI	OS_Exit

; ==========================================================================================================================================
; Module Initialisation

InitialisationCode
	STMFD	R13!,{R14}

	MOV	R0,#6				; Claim workspace from the module area.
	MOV	R3,#WS_Size
	SWI	XOS_Module
	LDMVSFD	R13!,{PC}

	STR	R2,[R12]			; If we claimed the memory, update the workspace pointer.

	ADRL	R0,TitleString			; Set up a filter on all Wimp tasks.
	ADR	R1,PostFilter
	MOV	R2,R12
	MOV	R3,#0
	MVN	R4,#&0100
	SWI	XFilter_RegisterPostFilter

	LDR	R12,[R12]			; Initialise the R12 workspace.
	ADD	R0,R12,#WS_PollBlock
	STR	R0,[R12,#WS_PollBlockPtr]

	MOV	R0,#0
	STR	R0,[R12,#WS_TaskHandle]
	STR	R0,[R12,#WS_ContentPtr]
	STR	R0,[R12,#WS_PollWord]

	MOV	R0,#&FF00			; Initialise the flags (enable all keypresses except Ctrl-S)
	STR	R0,[R12,#WS_FlagWord]

	MOV	R0,#-1				; Initialise the case conversion tables.
	SWI	XTerritory_LowerCaseTable
	STR	R0,[R12,#WS_LCTable]

	MOV	R0,#-1
	SWI	XTerritory_UpperCaseTable
	STR	R0,[R12,#WS_UCTable]

	MOV	R0,#-1
	MOV	R1,#3
	SWI	XTerritory_CharacterPropertyTable
	STR	R0,[R12,#WS_CPTable]

	MOV	R0,#-1
	MOV	R1,#1
	SWI	XTerritory_CharacterPropertyTable
	STR	R0,[R12,#WS_UPTable]

	LDMFD	R13!,{PC}

; ==========================================================================================================================================
; Module Finalisation

FinalisationCode
	STMFD	R13!,{R14}

	ADRL	R0,TitleString			; Deregister the filter.
	ADR	R1,PostFilter
	MOV	R2,R12
	MOV	R3,#0
	MVN	R4,#&01,24
	SWI	XFilter_DeRegisterPostFilter

	LDR	R12,[R12]			; Free the clipboard contents from the RMA.
	BL	FreeClipboardContents

	LDR	R0,[R12,#WS_TaskHandle]		; Quit the Wimp task, if it is running.
	CMP	R0,#0
	LDRGT	R1,TaskWord
	SWIGT	XWimp_CloseDown
	MOV	R1,#0
	STR	R1,[R12,#WS_TaskHandle]
	LDMVSFD	R13!,{PC}

	MOV	R0,#7				; Free the RMA workspace.
	MOV	R2,R12
	SWI	XOS_Module

	LDMFD	R13!,{PC}

; ------------------------------------------------------------------------------------------------------------------------------------------

TaskWord
	DCD	&4B534154

; ==========================================================================================================================================
; Post Filter Code

PostFilter
	TEQ	R0,#8				; Test for Key_Pressed events and pass on all else.
	MOVNE	PC,R14

	STMFD	R13!,{R0-R4,R14}

	LDR	R3,[R1,#0]		        ; Load the window handle into R3; pass on if -1.
	CMP	R3,#0
	LDMLTFD	R13!,{R0-R4,PC}

	LDR	R4,[R1,#4]			; Load the icon handle into R4; pass on if -1.
	CMP	R4,#0
	LDMLTFD	R13!,{R0-R4,PC}

	LDR	R12,[R12]			; Check to see if the Quote flag is set, and pass
	LDR	R0,[R12,#WS_FlagWord]		; on if it is.
	TST	R0,#F_Quote
	BICNE	R0,R0,#F_Quote
	STRNE	R0,[R12,#WS_FlagWord]
	LDMNEFD	R13!,{R0-R4,PC}

	LDR	R1,[R13,#4]
	LDR	R2,[R1,#24]			; Test the keypress against those that we respond to...
	TEQ	R2,#3				; Ctrl-C
	TEQNE	R2,#4				; Ctrl-D
	TEQNE	R2,#5				; Ctrl-E
	TEQNE	R2,#11				; Ctrl-K
	TEQNE	R2,#17				; Ctrl-Q
	TEQNE	R2,#19				; Ctrl-S
	TEQNE	R2,#20				; Ctrl-T
	TEQNE	R2,#22				; Ctrl-V
	TEQNE	R2,#24				; Ctrl-X
	TEQNE	R2,#26				; Ctrl-Z
	LDMNEFD	R13!,{R0-R4,PC}			; ...and exit if we don't get a match.

	TEQ	R2,#3				; Now test each key again, and check the relevant flag bit to see if
	TSTEQ	R0,#F_CtrlC			; the key is being accepted.  If not, exit.
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#4
	TSTEQ	R0,#F_CtrlD
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#5
	TSTEQ	R0,#F_CtrlE
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#11
	TSTEQ	R0,#F_CtrlK
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#17
	TSTEQ	R0,#F_CtrlQ
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#19
	TSTEQ	R0,#F_CtrlS
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#20
	TSTEQ	R0,#F_CtrlT
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#22
	TSTEQ	R0,#F_CtrlV
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#24
	TSTEQ	R0,#F_CtrlX
	LDMEQFD	R13!,{R0-R4,PC}

	TEQ	R2,#26
	TSTEQ	R0,#F_CtrlZ
	LDMEQFD	R13!,{R0-R4,PC}

	MVN	R14,#0				; We've got this far; now we claim this poll and don't pass
	STR	R14,[R13,#0]			; it on to the task.

	TEQ	R2,#&11				; Ctrl-Q.  Set the Quote flag and exit.
	LDREQ	R0,[R12,#WS_FlagWord]
	ORREQ	R0,R0,#F_Quote
	STREQ	R0,[R12,#WS_FlagWord]
	LDMEQFD	R13!,{R0-R4,PC}

	LDR	R1,[R12,#WS_PollBlockPtr]	; Get the icon details, using the window and icon
	STR	R3,[R1,#0]			; handles we found earlier.
	STR	R4,[R1,#4]
	SWI	XWimp_GetIconState
	LDMVSFD	R13!,{R0-R4,PC}

	MOV	R14,R2				; Stick the keypress into R14 out of the way.

	LDR	R0,[R1,#24]			; Load the icon flags, and check that it's indirected...
	TST	R0,#&01,24
	BEQ	PostFilterNonIndirected		; ...if it isn't, we handle the text with a special case.

	STMFD	R13!,{R0-R1,R14}
	MOV	R0,#-1				; Find the limit of application space on this machine.
	SWI	XOS_ReadDynamicArea
	LDMVSFD	R13!,{R0-R1,R14}
	LDMVSFD	R13!,{R0-R4,PC}

	ADD	R0,R0,R2
	LDR	R1,[R12,#WS_PollBlockPtr]       ; Check if the address is within the application space...
	LDR	R2,[R1,#28]
	CMP	R2,R0
	LDMFD	R13!,{R0-R1,R14}
	BGE	PostFilterMemoryMappedOK	; ...if it isn't, we know we can access it, otherwise...

	STMFD	R13!,{R0-R3,R14}		; ...collect and compare the task handle of the icon's owner with
	LDR	R1,[R12,#WS_PollBlockPtr]	; the current task handle, and exit if they are not the same.
	LDR	R2,[R1,#0]			; If the icon doesn't belong to the current task, the indirected
	LDR	R3,[R1,#4]			; data will be mapped out of memory...
	ADD	R1,R1,#&80
	MOV	R0,#20
	STR	R0,[R1,#0]
	MOV	R0,#0
	STR	R0,[R1,#12]
	MOV	R0,#19
	SWI	XWimp_SendMessage
	BLVS	ReportWimpError

	MOV	R0,#5
	SWI	XWimp_ReadSysInfo
	BLVS	ReportWimpError
	CMP	R0,R2
	LDMFD	R13!,{R0-R3,R14}
	LDMNEFD	R13!,{R0-R4,PC}

PostFilterMemoryMappedOK
	SUB	R3,R2,#1			; We now know that we can access the indirected memory.

PostFilterStrLenLoop
	LDRB	R0,[R3,#1]!			; Find the length of the (asssumed control terminated) string.
	CMP	R0,#32
	BGE	PostFilterStrLenLoop

	SUB	R3,R3,R2			; Store the string length into R3 (R2 is address of string).

PostFilterBranch
	ADD	R3,R3,R2			; R2 = String start; R3 = String end.

	TEQ	R14,#3				; Ctrl-C
	TEQNE	R14,#&18			; Ctrl-X
	BEQ	PostFilterCutCopy

	TEQ	R14,#&16			; Ctrl-V
	TEQNE	R14,#&1A			; Ctrl-Z
	BEQ	PostFilterPasteReplace

	TEQ	R14,#4				; Ctrl-D
	BEQ	PostFilterRemoveExt

	TEQ	R14,#5				; Ctrl-E
	BEQ	PostFilterKeepExt

	TEQ	R14,#&0B			; Ctrl-K
	BEQ	PostFilterDeleteBack

	TEQ	R14,#&13			; Ctrl-S
	BEQ	PostFilterSwapCase

	TEQ	R14,#&14			; Ctrl-T
	BEQ	PostFilterInsertDate

	LDMFD	R13!,{R0-R4,PC}

; ------------------------------------------------------------------------------------------------------------------------------------------
; Count the length of a non-indirected icon.  R3 returns the number of characters (excluding terminator).

PostFilterNonIndirected
	ADD	R2,R1,#28			; Point R2 to the start of the icon text in the icon block.
	MOV	R3,#0

PostFilterNonIndirectedLoop
	LDRB	R0,[R2,R3]			; Count the number of characters in the string, terminating
	CMP	R0,#&20				; when a ctrl character is met or the 12 character limit is up.
	BLT	PostFilterBranch

	ADD	R3,R3,#1
	CMP	R3,#12
	MOVGT	R3,#12
	BGE	PostFilterBranch
	B	PostFilterNonIndirectedLoop

; ==========================================================================================================================================
; Cut or copy the contents of an icon to our clipboard, claiming memory from the RMA to do so.
;
; On entry R2=Start of text; R3=End of text.

PostFilterCutCopy
	LDR	R0,[R12,#WS_ContentPtr]		; If we don't already own the clipboard, set the pollword so that a
	CMP	R0,#0				; Message_ClaimEntity is sent out when we get back to our own task.
	MOVEQ	R0,#&43				; (Ctrl-C)
	STREQ	R0,[R12,#WS_PollWord]

	BL	FreeClipboardContents		; Throw away anything currently in the clipboard.

	MOV	R4,R2				; Claim memory from the RMA to hold the text between R2 and R3.
	SUB	R3,R3,R2			; The length of the text is stored for future use
	STR	R3,[R12,#WS_ContentLen]
	ADD	R3,R3,#1
	MOV	R0,#6
	SWI	XOS_Module
	STR	R2,[R12,#WS_ContentPtr]
	MOV	R14,R4

PostFilterCutCopyLoop				; Copy the icon text into our workspace.
	SUBS	R3,R3,#1
	BLE	PostFilterCutCopyLoopExit
	LDRB	R0,[R4],#1
	STRB	R0,[R2],#1
	B	PostFilterCutCopyLoop

PostFilterCutCopyLoopExit
	MOV	R0,#0				; Terminate the copied clipboard text.
	STRB	R0,[R2,#0]

	LDR	R1,[R13,#4]			; Check the keypress.  If it was Ctrl-C, exit.
	LDR	R0,[R1,#&018]
	TEQ	R0,#&18				; Ctrl-X
	LDMNEFD	R13!,{R0-R4,PC}

	MOV	R0,#&0D				; If the keypress was Ctrl-X, clear the icon contents
	STRB	R0,[R14,#0]			; by placing a CR at the start and refreshing it.
	B	PostFilterRefreshIcon

; ==========================================================================================================================================
; Insert the clipboard contents at the caret, using OS_Byte &8A.  If Ctrl-Z was used, prefix the
; text with a Ctrl-U to clear the icon.
;
; On entry R14=Keypress.

PostFilterPasteReplace
	CMP	R14,#&1A			; If the keypress was Ctrl-Z, we insert a Ctrl-U into
	MOV	R0,#&8A				; the keyboard buffer to wipe the old text.
	MOV	R1,#0
	MOVEQ	R2,#&15
	SWIEQ	XOS_Byte

	LDR	R4,[R12,#WS_ContentPtr]		; Check if we own the clipboard.  If we do, we can
	CMP	R4,#0				; just insert the text from the RMA.  If we don't...
	BNE	PostFilterPasteReplaceInsert

	MOV	R0,#&56				; ...we need to set the pollword so that we can send
	STR	R0,[R12,#WS_PollWord]		; a message for the clipboard contents when we next
	LDMFD	R13!,{R0-R4,PC}			; get into the Wimp_Poll loop.

PostFilterPasteReplaceInsert
	LDRB	R2,[R4],#1			; R4 points to the clipboard contents in RMA, so start
	CMP	R2,#0				; to insert the text into the keyboard buffer until a
	LDMEQFD R13!,{R0-R4,PC}			; zero byte is found.

	TST	R2,#&80				; If the top bit is set, prefix with a zero byte.
	BEQ	PostFilterPasteReplaceInsertSkip
	MOV	R2,#0
	SWI	XOS_Byte
	LDRB	R2,[R4,#-1]

PostFilterPasteReplaceInsertSkip
	SWI	XOS_Byte			; Insert the string into the kayboard buffer.
	LDMCSFD	R13!,{R0-R4,PC}
	B	PostFilterPasteReplaceInsert

; ==========================================================================================================================================
; Insert Date
;
; Insert the current date into the keyboard buffer.

PostFilterInsertDate
	ADR	R0,InsertDateFormatVar
	LDR	R1,[R12,#WS_PollBlockPtr]
	ADD	R1,R1,#110
	MOV	R2,#110
	MOV	R3,#0
	MOV	R4,#0
	SWI	XOS_ReadVarVal
        BVS	PostFilterInsertDateFixed

PostFilterInsertDateVariable
	MOV	R0,#0
	STRB	R0,[R1,R2]
	MOV	R4,R1

	B	PostFilterInsertDateReadTime

PostFilterInsertDateFixed
	ADR	R4,InsertDateFormat

PostFilterInsertDateReadTime
	MOV	R0,#3				; Read the RTC into the poll block, as a 5-byte value.
	LDR	R1,[R12,#WS_PollBlockPtr]
	STR	R0,[R1]
	MOV	R0,#14
	SWI	XOS_Word
	BVS     PostFilterInsertDateExit

	MVN	R0,#0				; Convert the 5-byte value to a string.
	ADD	R2,R1,#10
	MOV	R3,#100
	SWI	XTerritory_ConvertDateAndTime	; By this point, R4 points to the format string.

PostFilterInsertDateExit
	MOVVC	R4,R0				; Point R4 to the string, and set up R0 and R1 ready for OS_Byte &8A before jumping
	MOV	R0,#&8A				; to the insert text loop.  If the conversion failed, R4 is left pointing to the
	MOV	R1,#0				; format string (so that will be inserted instead).
	B	PostFilterPasteReplaceInsert

InsertDateFormat
	DCB	"%DY %M3 %CE%YR",0

InsertDateFormatVar
	DCB	"IcnClipBrd$DateFormat",0
	ALIGN

; ==========================================================================================================================================
; Free Clipboard Contents
;
; Release the module area space used by the clipboard contents.

FreeClipboardContents
	STMFD	R13!,{R0-R2,R14}		; Check that we currently have something on the clipboard.
	LDR	R2,[R12,#WS_ContentPtr]
	CMP	R2,#0
	LDMEQFD	R13!,{R0-R2,PC}

	MOV	R0,#7				; If we have clipboard contents in the RMA, free that contents.
	SWI	XOS_Module
	MOV	R0,#0
	STR	R0,[R12,#WS_ContentPtr]
	LDMFD	R13!,{R0-R2,PC}

; ==========================================================================================================================================
; Keep a file extension, and delete the rest.
;
; On entry, R2=Start of text; R3=End of text.

PostFilterKeepExt
	MOV	R4,R2

PostFilterKeepExtLoop				; Search through the string, looking for '/' to show where
	CMP	R4,R3   			; the file extension begins.
	LDMGEFD	R13!,{R0-R4,PC}

	LDRB	R0,[R4,#1]!
	CMP	R0,#&2F				; '/'
	BNE	PostFilterKeepExtLoop

; ------------------------------------------------------------------------------------------------------------------------------------------
; Delete text up to a given point.
;
; On entry, R2=Start of text; R3=End of text; R4=Delete point.

DeleteToStartOfText
	CMP	R4,R3				; Copy the text back to the start of the buffer.
	BGE	DeleteToStartOfTextExit
	LDRB	R0,[R4],#1
	STRB	R0,[R2],#1
	B	DeleteToStartOfText

DeleteToStartOfTextExit
	MOV	R0,#0				; Terminate the new buffer contents.
	STRB	R0,[R2,#0]

	LDR	R1,[R12,#WS_PollBlockPtr]	; *** Is there any reason why this doesn't just call PostFilterRefreshIcon?
	MOV	R0,#0
	STR	R0,[R1,#8]
	STR	R0,[R1,#12]
	SWI	XWimp_SetIconState
	SWI	XWimp_GetCaretPosition
	LDMIA	R1,{R0-R4}
	STMFD	R13!,{R5}
	MOV	R5,#0
	SWI	XWimp_SetCaretPosition
	LDMFD	R13!,{R5}
	LDMFD	R13!,{R0-R4,PC}

; ==========================================================================================================================================
; Delete the text from the caret to the start of the icon.
;
; On entry, R2=Start of text; R3=End of text.

PostFilterDeleteBack
	LDR	R1,[R12,#WS_PollBlockPtr]	; Get the index of the caret into the string.
	SWI	XWimp_GetCaretPosition
	LDR	R4,[R1,#20]
	ADD	R4,R4,R2
	CMP	R4,R2				; Check that the index isn't negative (-1 is no caret).
	LDMLEFD R13!,{R0-R4,PC}

	B	DeleteToStartOfText

; ==========================================================================================================================================
; Swap the case of the character after the caret, and move the caret on one.
;
; On entry, R2=Start of text; R3=End of text.

PostFilterSwapCase
	LDR	R1,[R12,#WS_PollBlockPtr]	; Get the index of the caret into the string.
	SWI	XWimp_GetCaretPosition
	LDR	R4,[R1,#20]
	ADD	R4,R4,R2
	CMP	R4,R3				; Check that we're not at the end of the text.
	LDMGEFD	R13!,{R0-R4,PC}

	LDRB	R1,[R4]				; Load the character after the caret into R1

	LDR	R0,[R12,#WS_UPTable]		; Get the flag byte containing the bit for the next character into R2.
	MOV	R2,R1,LSR #3
	LDRB	R2,[R0,R2]

	AND	R3,R1,#&7			; Get the flag bit into R0.
	MOV	R0,#1
	MOV	R0,R0,LSL R3

	TST	R2,R0				; Test to see if the char in R1 is uppercase.
	LDREQ	R3,[R12,#WS_UCTable]		; ...we convert to upper case, else...
	LDRNE	R3,[R12,#WS_LCTable]		; ...we convert to lower case.
	LDRB	R1,[R3,R1]
        STRB    R1,[R4]

	MOV	R0,#0				; Refresh the icon and move the caret on
	LDR	R1,[R12,#WS_PollBlockPtr]
	STR	R0,[R1,#8]
	STR	R0,[R1,#12]
	SWI	XWimp_SetIconState
	SWI	XWimp_GetCaretPosition
	LDR	R4,[R1,#20]
	LDMIA	R1,{R0-R1}
	STMFD	R13!,{R5}
	ADD	R5,R4,#1
	MVN	R4,#0
	SWI	XWimp_SetCaretPosition
	LDMFD	R13!,{R5}

	LDMFD	R13!,{R0-R4,PC}

; ==========================================================================================================================================
; Remove the extension and fix the remaining text's case.
;
; On entry, R2=Start of text; R3=End of text.

PostFilterRemoveExt
	MOV	R0,R2

RemoveExtStopLoop
	CMP	R2,R3				; Find the last '.' in the text, and update R0 to point to the character after it.
	BGE	RemoveExtStopLoopExit
	LDRB	R1,[R2],#1
	CMP	R1,#&2E				; '.'
	MOVEQ	R0,R2
	B	RemoveExtStopLoop

RemoveExtStopLoopExit
	MOV	R14,#1				; Set R2 to point to the start of the text after the last '.'.
	MOV	R2,R0

RemoveExtUpdateLoop
	CMP	R2,R3				; Exit if the end of the text is reached.
	BGE	PostFilterRefreshIcon

	LDRB	R1,[R2],#1			; If a '/' is found, terminate the text there with a CR and exit.
	CMP	R1,#&2F				; '/'
	MOVEQ	R1,#&0D
	STREQB	R1,[R2,#-1]
	BEQ	PostFilterRefreshIcon

	LDR	R0,[R12,#WS_CPTable]		; Get the flag byte containing the bit for the next character into R4.
	MOV	R4,R1,LSR #3
	LDRB	R4,[R0,R4]

	AND	R1,R1,#&7			; Get the flag bit position set in R0.
	MOV	R0,#1
	MOV	R0,R0,LSL R1

	LDRB	R1,[R2,#-1]			; We corrupted R1 in the process, so reload it.

	TST	R4,R0				; Test to see if the char in R1 is alphabetic.  If not, set R14 and continue.
	MOVEQ	R14,#1
	BEQ	RemoveExtUpdateLoop

RemoveExtCheckCase
	CMP	R14,#1				; Otherwise, it's alphabetic.  If R14 is set, the last char was not, so...
	LDREQ	R4,[R12,#WS_UCTable]		; ...we convert to upper case, else...
	LDRNE	R4,[R12,#WS_LCTable]		; ...we convert to lower case.
	LDRB	R1,[R4,R1]
	STRB	R1,[R2,#-1]
	MOV	R14,#0				; Clear the R14 flag, and continue.
	B	RemoveExtUpdateLoop

; ------------------------------------------------------------------------------------------------------------------------------------------
; Refresh the icon and put the caret back at the start.
;
; This relies on the window and icon handles being present in the poll-block following the start of the filter code.

PostFilterRefreshIcon
	LDR	R1,[R12,#WS_PollBlockPtr]
	MOV	R0,#0
	STR	R0,[R1,#8]
	STR	R0,[R1,#12]
	SWI	XWimp_SetIconState
	SWI	XWimp_GetCaretPosition
	LDMIA	R1,{R0-R4}
	STMFD	R13!,{R5}
	MVN	R5,#0
	SWI	XWimp_SetCaretPosition
	LDMFD	R13!,{R5}
	LDMFD	R13!,{R0-R4,PC}

; ==========================================================================================================================================
; Command IcnClipBrdKeys

CommandCode_Keys
	LDR	R12,[R12]
	STMFD	R13!,{R14}

	TEQ	R1,#0				; If parameters=0, print the keys in use; if =1, set the keys
	BEQ	CommandKeys_Show

CommandKeys_Set
	MOV	R1,R0				; Convert the parameter into a number.
	MOV	R0,#10
	ORR	R0,R0,#&80000000
	SWI	XOS_ReadUnsigned
	LDMVSFD	R13!,{PC}

	MOV	R1,#&00FF
	ORR	R1,R1,#&0300

	AND	R2,R2,R1			; Mask the number down to a single byte plus 1, to be safe.

	LDR	R0,[R12,#WS_FlagWord]		; Take the number and replace the 2nd byte plus 1 of the flags with it.
	BIC	R0,R0,R1,ASL #8
	ORR	R0,R0,R2,ASL #8
	STR	R0,[R12,#WS_FlagWord]

	LDMFD	R13!,{PC}

CommandKeys_Show
	SWI	XOS_WriteS
	DCB	"The keys being intercepted are:",0
	ALIGN
	SWI	XOS_NewLine

	LDR	R6,[R12,#WS_FlagWord]

	ADR	R0,CtrlText
	MOV	R1,#5

	TST	R6,#F_CtrlC
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+67
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlD
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+68
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlE
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+69
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlK
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+75
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlQ
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+81
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlS
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+83
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlT
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+84
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlV
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+86
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlX
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+88
	SWINE	OS_WriteI+32

	TST	R6,#F_CtrlZ
	SWINE	XOS_WriteN
	SWINE	OS_WriteI+90
	SWINE	OS_WriteI+32

	SWI	XOS_NewLine

	LDMFD	R13!,{PC}

CtrlText
	DCB	"Ctrl-",0
	ALIGN

; ==========================================================================================================================================
; Command Desktop_IcnClipBrd

CommandCode_Desktop
	LDR	R12,[R12]
	STMFD	R13!,{R14}
	LDR	R0,[R12,#WS_TaskHandle]
	CMP	R0,#0
	ADRGT	R0,ErrorBlock
	MSRGT	CPSR_f,#9<<28
	LDMGTFD	R13!,{PC}
	MOV	R0,#2
	ADR	R1,TitleString
	MOV	R2,#0
	SWI	XOS_Module
	LDMFD	R13!,{PC}

; ==========================================================================================================================================
; Service Call Handler

ServiceCallHandler
	LDR	R12,[R12]
	STMFD	R13!,{R14}

;	TEQ	R1,#Service_TerritoryStarted
;	BEQ	ServiceCall_TerritoryStarted

	TEQ	R1,#Service_StartWimp
	BEQ	ServiceCall_StartWimp

	TEQ	R1,#Service_PostReset
	MOVEQ	R14,#0
	STREQ	R14,[R12,#WS_TaskHandle]

	TEQ	R1,#Service_StartedWimp
	LDMNEFD	R13!,{PC}

	LDR	R14,[R12,#WS_TaskHandle]
	CMN	R14,#1
	MOVEQ	R14,#0
	STREQ	R14,[R12,#WS_TaskHandle]
	LDMFD	R13!,{PC}

ServiceCall_StartWimp
	LDR	R14,[R12,#WS_TaskHandle]
	TEQ	R14,#0
	MVNEQ	R14,#0
	STREQ	R14,[R12,#WS_TaskHandle]
	ADREQL	R0,CommandTable
	MOVEQ	R1,#0
	LDMFD	R13!,{PC}

ServiceCall_TerritoryStarted
;	MOV	R0,#-1				; Initialise the case conversion tables.
;	SWI	XTerritory_LowerCaseTable
;	STR	R0,[R12,#WC_LCTable]

;	MOV	R0,#-1
;	SWI	XTerritory_UpperCaseTable
;	STR	R0,[R12,#WC_UCTable]
;	LDMFD	R13!,{PC}


; ==========================================================================================================================================
; Module title and help texts.

HelpString
	DCB	"IcnClipBrd\t",$BuildVersion," (",$BuildDate,") 32-bit ",169," Thomas Leonard & Stephen Fryatt",0

TitleString
	DCB	"IcnClipBrd",0
	ALIGN

ErrorBlock
	DCD	0
	DCB	"IcnClipBrd is already running",0 ; Error Block String -/-

CommandDesktopHelp
	DCB	"IcnClipBrd provides cut and paste features in writeable icons.",13
	DCB	"Do not use *",27,0,", use *Desktop instead.",0

CommandKeysHelp
	DCB	"*",27,0," sets or displays the keys intercepted by IcnClipBrd.",13
	DCB	"<new keys> is a number formed of binary digits %TSZXVQKEDC.",13

CommandKeysSyntax
	DCB	27,30,"<new keys>]",0

	END
