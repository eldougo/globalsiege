Attribute VB_Name = "modRandom"
Option Explicit

'The Windows API function CryptGenRandom() replaces the VB6 rnd() function. Function
'GenRandom4() is a straight replacement for rnd() returning a single (4 bytes long)
'generated by CryptGenRandom() and GenRandom1() returns a random byte with the passed
'maximum value also using CryptGenRandom().
'
'CryptGenRandom() is certified cryptographic strength by Microsoft.
'
'GenRandom4() uses a 1 meg buffer which is efficiently created by the CryptGenRandom()
'API function. The buffer is refilled with random characters when the pointer is at the
'end. This method dramatically increases the speed of the random number generator.

Private Declare Function CryptAcquireContext Lib "advapi32.dll" Alias "CryptAcquireContextA" (ByRef phProv As Long, ByVal pszContainer As Long, ByVal pszProvider As Long, ByVal dwProvType As Long, ByVal dwFlags As Long) As Long
Private Declare Function CryptGenRandom Lib "advapi32.dll" (ByVal hProv As Long, ByVal dwLen As Long, ByVal pbBuffer As String) As Long
Private Declare Function CryptReleaseContext Lib "advapi32.dll" (ByVal hProv As Long, ByVal dwFlags As Long) As Long
Private Const PROV_RSA_FULL  As Long = 1
Private Const CRYPT_VERIFYCONTEXT As Long = &HF0000000

'For the random number generator.
Dim gRandomContextHandle As Long

'Globals to speed up GenRandom4().
Private gRandomString As String
Private Const gRandomStringLength As Long = 1000000
Private gRandomStringIndex As Long

'Globals for GenRepeatRandom4().
Private gRepeatString As String
Private Const gRepeatStringLength As Long = 10000
Private gRepeatStringIndex As Long


'Random number generator functions.
'Return 1 byte random number greater than or equal to 0 and less than pMaxVal.
Public Function GenRandom1(Optional pMaxVal As Long = &H10) As Long
    Dim vRandomBytes As String
    Dim vIndex As Long
    Dim rVal As Long
    Dim vIX As Long
    
    On Error GoTo ErrHand
    
    If pMaxVal > &H10 Then
        pMaxVal = &H10
    End If
    
    If gRandomContextHandle = 0 Then
        GenRandom1 = Int(Rnd * pMaxVal)
        Exit Function
    End If
    
    vRandomBytes = "0"
    GenRandom1 = 0
    
    If CryptGenRandom(gRandomContextHandle, 1, vRandomBytes) = 0 Then
        GenRandom1 = Int(Rnd * pMaxVal)
        Exit Function
    End If
    
    GenRandom1 = (Asc(Mid(vRandomBytes, 1, 1)) * pMaxVal) / &H10
    Exit Function
ErrHand:
    GenRandom1 = Rnd
    Exit Function
End Function

'Return a random value of type single less than 1 but greater than or equal to zero.
'Use in place of VB's rnd function.
'Speed up the random number generator by using a random string buffer.
Public Function GenRandom4() As Single
    Dim vRandomBytes As String
    Dim vIndex As Long
    Dim rVal As Long
    Dim vIX As Long
    
    On Error GoTo ErrHand
    
    'Fill the buffer up if pointer is at 0.
    If gRandomStringIndex = 0 Then
        If CryptGenRandom(gRandomContextHandle, gRandomStringLength, gRandomString) = 0 Then
            GenRandom4 = Rnd
            Exit Function
        End If
    End If
    
    'The for loop is to trap "FFFFFFFF" which is gets rounded up to 1 causing problems.
    For vIX = 0 To 1000
        
        'Get the next four bytes from the string buffer.
        For vIndex = 0 To 3
            GenRandom4 = GenRandom4 + _
            CLng(Asc(Mid(gRandomString, gRandomStringIndex + vIndex + 1, 1))) * 2 ^ (vIndex * 8)
        Next
        
        'Update index and refresh buffer if at the end.
        gRandomStringIndex = gRandomStringIndex + 4
        If gRandomStringIndex > gRandomStringLength - 6 Then
            gRandomStringIndex = 0
        End If
        
        GenRandom4 = (GenRandom4 / &H10000000) / &H10
        If GenRandom4 <> 1 Then
            Exit For
        End If
    Next
    
    Exit Function
ErrHand:
    GenRandom4 = Rnd
    Exit Function
End Function

'Generate a repeatable random string.
'Private gRepeatString As String
'Private Const gRepeatStringLength As Long = 10000
'Private gRepeatStringIndex As Long
Public Function GenRepeat4(Optional pReset As Boolean = False) As Single
    Dim vRandomBytes As String
    Dim vIndex As Long
    Dim rVal As Long
    Dim vIX As Long
    Static vStringLoaded As Boolean
    
    On Error GoTo ErrHand
    
    'Fill the buffer when run for the first time.
    If Not vStringLoaded Then
        If CryptGenRandom(gRandomContextHandle, gRepeatStringLength, gRepeatString) = 0 Then
            GenRepeat4 = Rnd
            Exit Function
        End If
        vStringLoaded = True
    End If
    
    If pReset Then
        gRepeatStringIndex = 0
    End If
    
    'The for loop is to trap "FFFFFFFF" which is rounded up to 1.
    For vIX = 0 To 1000
        
        'Get the next four bytes from the string buffer.
        For vIndex = 0 To 3
            GenRepeat4 = GenRepeat4 + _
            CLng(Asc(Mid(gRepeatString, gRepeatStringIndex + vIndex + 1, 1))) * 2 ^ (vIndex * 8)
        Next
        
        'Update index and refresh buffer if at the end.
        gRepeatStringIndex = gRepeatStringIndex + 4
        If gRepeatStringIndex > gRepeatStringLength - 6 Then
            gRepeatStringIndex = 0
        End If
        
        GenRepeat4 = (GenRepeat4 / &H10000000) / &H10
        If GenRepeat4 <> 1 Then
            Exit For
        End If
    Next
    
    Exit Function
ErrHand:
    GenRepeat4 = Rnd
    Exit Function
End Function

'Acquire random context.
Public Function InitialiseRandomNumberGenerator() As Long
    InitialiseRandomNumberGenerator = CryptAcquireContext(gRandomContextHandle, 0, 0, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT)
    gRandomString = String(gRandomStringLength, "0")
    gRepeatString = String(gRepeatStringLength, "0")
    gRandomStringIndex = 0
End Function

'Release random context.
Public Function ReleaseRandomNumberGenerator() As Long
    ReleaseRandomNumberGenerator = CryptReleaseContext(gRandomContextHandle, CRYPT_VERIFYCONTEXT)
End Function