grammar GCODE;

options {
	language = Java; k=1;
}

@lexer::header {
	package GCODECompiler;
}

@header {
	package GCODECompiler;
	import GCODECompiler.GCODEHandler;
	import java.io.IOException;
	import java.io.StringReader;
	import java.io.FileReader;
	import java.io.BufferedReader;
}

@members {
		GCODEHandler h;

	  public GCODEParser(BufferedReader fileIn) throws IOException {			
			this(new CommonTokenStream(
							new GCODELexer(
									new ANTLRReaderStream(fileIn))));
			h = new GCODEHandler (input);
		}
	  public GCODEParser(String docIn) throws IOException {		
			this(new CommonTokenStream(
							new GCODELexer(
								new ANTLRReaderStream(
											new StringReader (docIn))))); 
			h = new GCODEHandler (input);
		}

  public GCODEHandler getHandler() {
    return h;
  }
  
  public List<String> getErrorList () {
    return h.getErrorList();
  }

  public void displayRecognitionError(String[] tokenNames,RecognitionException e) {
		String hdr = " * " + getErrorHeader(e);
		String msg = " - " + getErrorMessage(e, tokenNames);
		h.handleError(tokenNames, e, hdr, msg);
  }

}

/*La struttura standard che abbiamo deciso di prendere in consideraione è la seguente:
1) Si specifica l'uso di coordinate assolute o relative, si seleziona l'utensile e la modalità di utilizzo (config)
2) Si specificano i vari parametri dell'utensile e le modalità di lavoro (config)
3) Spostamento veloce verso i punto di inizio (gcommall)
4) Vari movimenti con interpolazione (gcommall)
5) Fine lavoro con movimento veloce lontano dal pezzo e spegnimento utensile (exit)

Un esempio è il seguente:
G90 T0101 M06 (config)
G94 G97 F400 S260 M04 M08 (config)
G00 X45 Y0 (gcommall)
G01 X20 Y20 (gcommall)
G02 X30 Y30 I40 J20 (gcommall)
G00 X100 Y100 (exit)
M05 M09 M30 (exit)
*/

// Parser definition
gCode //returns [List<String> p]
	:	(c=config	{h.printConfig(c);}
		mov=gCommAll	{h.printCommand(mov);}
		e=exit		{h.printExit(e);}
			)
	;
	
exit returns [List<String> list]
@init { list = new ArrayList<String>();}
	:	mv=gCommCoordFast	{h.addMovement (list, mv);} 
		a=mConfig		{h.addListToStringList(list,a);}	
	;

config returns [List<String> list]
@init { list = new ArrayList<String>();}
	:	a=GCODESCOORD	{h.addTokenToStringList(list,$a);}
		b=TCODES 	{h.addTokenToStringList(list,$b);}
		c=MCODES 	{h.addTokenToStringList(list,$c);}
			a1=GCODESF?	{h.addTokenToStringList(list,$a1);}
			b1=GCODESS?	{h.addTokenToStringList(list,$b1);}
			c1=FCODES?	{h.addTokenToStringList(list,$c1);}
			d1=SCODES?	{h.addTokenToStringList(list,$d1);}
			
		d=mConfig 	{h.addListToStringList(list,d);}
	;

	
mConfig returns [List<String> list]
@init { list = new ArrayList<String>();}
	:	(	a=MCODES {h.addTokenToStringList(list,a);}
			)* 
	;


gCommAll returns [List<String> listMove]
@init { listMove = new ArrayList<String>();}
	:	mv=gCommCoordFast	{h.addMovement (listMove, mv);} 
		(	mw=gCommCoordNoInt	{h.addMovement (listMove, mw);}
		|	mx=gCommCoordInt	{h.addMovement (listMove, mx);}
			)+
	; 
	
	
gCommCoordFast returns [String mv]
	:	g=GCODESFAST (x=XCOORD y=YCOORD) {mv = h.createMovement ($g, $x, $y);}
	;


gCommCoordNoInt returns [String mw]
	:	g=GCODESINT (x=XCOORD y=YCOORD) {mw = h.createMovement ($g, $x, $y);}
	;
	
gCommCoordInt returns [String mx]
	:	g=GCODESINTCIRC (x=XCOORD y=YCOORD) (i=ICOORD j=JCOORD) {mx = h.createMovement($g,$x,$y,$i,$j);}
	;
	
//Lexer definition
GCODESCOORD
	:	'G' ('90'|'91')
	;
	
GCODESFAST
	:	'G' '00'
	;
	
GCODESINT
	:	'G' ('01')
	;
	
GCODESINTCIRC
	:	'G' ('02'|'03')
	;

GCODESCOMP
	:	'G' ('40'|'41'|'42')
	;
	
GCODESF
	:	'G' ('94'|'95')
	;
	
GCODESS
	:	'G' ('96'|'97')
	;
	
TCODES
	:	'T' ('0'..'9' '0'..'9')+
	;
	
MCODES
	:	'M' ('00'|'03'|'04'|'05'|'06'|'08'|'09'|'10'|'11'|'30'|'60'|'72')
	;
	
XCOORD
	:	'X' ('+' | '-')? INT
	;
	
YCOORD
	:	'Y' ('+' | '-')? INT
	;

ICOORD
	:	'I' (ADD | SUB)? INT
	;

JCOORD
	:	'J' (ADD | SUB)? INT
	;
	
SCODES
	:	'S' ('0'..'9')+
	;
	
FCODES
	:	'F' ('0'..'9')+
	;
	


ADD	: '+';
SUB	:	'-';
MUL	:	'*';
DIV	:	'/';	
COMMA :	',';
SC 	: ';';
DOT : '.';
LB 	: '{';
RB 	:	'}';
EQ 	: '=';
LP	:	'(';
RP	:	')';

PACKAGE : 'package';

//ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;

INT :	'0'..'9'+
	;

FLOAT
    :   ('0'..'9')+ '.' ('0'..'9')* EXPONENT?
    |   '.' ('0'..'9')+ EXPONENT?
    |   ('0'..'9')+ EXPONENT
    ;

COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) {$channel=HIDDEN;}
    ;

STRING
    :  '"' ( ESC_SEQ | ~('\\'|'"') )* '"'
    ;

CHAR:  '\'' ( ESC_SEQ | ~('\''|'\\') ) '\''
    ;

fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
ESC_SEQ
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   UNICODE_ESC
    |   OCTAL_ESC
    ;

fragment
OCTAL_ESC
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UNICODE_ESC
    :   '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    ;

SCAN_ERROR	: . ;
