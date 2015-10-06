VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Scan3DPreparation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
Option Explicit

Private MSComm1 As MSComm   'MSCOMM��
Private JPGInfoReader As ExifReader 'JPG�ļ���EXIF  ֻ��ȡ���еĽ�����Ϣ

'����������������������ࡪ����������������������
Public Type Type_PointWithID
IsQualified As Integer
gID As Integer
End Type

Private IdenPointCount As Integer '��ʶ�����
Private IdenPoint() As TV_2DVECTOR '��ʶ��
Private RealVisibleWidth As Single '���ӿ���
Private RealVisibleHeight As Single '���Ӹ߶�

Sub AnalyzeIdentificationPoint()
'���ڷ���һ��ͼƬ����ı�ʶ�������һ�����أ���������ֻ��Ҫһ��ʸ����
'����ÿ����ʶ��͵���һ����
Dim pixel() As Type_PointWithID, SamplePoint() As TV_2DVECTOR
Dim GROUP_POINTER As Integer, CanCreateGroup As Boolean
GROUP_POINTER = 0
Dim PW As Long, PH As Long
PW = PictureWidth
PH = PictureHeight
ReDim pixel(1 To PW, 1 To PH) As Type_PointWithID
'����������������ͼƬ����������������
TexF.LoadTexture App.Path & "\Group\Measure.jpg", "Measure", PW, PH
TexF.LockTexture GetTex("Measure")
'������������ѡ�㡪��������������
Dim tmpColor As Long, tmpC As TV_COLOR, i As Long, j As Long
For i = 1 To PW
       For j = 1 To PH
       tmpColor = TexF.GetPixel(GetTex("Measure"), i, j)
       tmpC = DecodeRGBA(tmpColor)
       If tmpC.r > 0.7 And tmpC.g < 0.4 And tmpC.b < 0.4 Then '��
       pixel(i, j).IsQualified = 1                                                  '����ƫ�򣿣� ����ѡ�еĵ�
       End If
       '.gid = 0
       Next j
Next i

'������������

For i = 2 To PW - 1
       For j = 2 To PH - 1
       If pixel(i, j).gID = 0 And pixel(i, j).IsQualified = 1 Then '��û�зֵ������ȥ����
              CanCreateGroup = True
               '���Ϸ��С����ѡ��Ͳ����½�һ������
              If pixel(i - 1, j - 1).IsQualified = 1 And pixel(i - 1, j - 1).gID <> 0 Then
              pixel(i, j).gID = pixel(i - 1, j - 1).gID
              CanCreateGroup = False
              End If
              If pixel(i - 1, j).IsQualified = 1 And pixel(i - 1, j).gID <> 0 Then
              pixel(i, j).gID = pixel(i - 1, j).gID
              CanCreateGroup = False
              End If
              If pixel(i, j - 1).IsQualified = 1 And pixel(i, j - 1).gID <> 0 Then
              pixel(i, j).gID = pixel(i, j - 1).gID
              CanCreateGroup = False
              End If
              If pixel(i - 1, j + 1).IsQualified = 1 And pixel(i - 1, j + 1).gID <> 0 Then
              pixel(i, j).gID = pixel(i - 1, j + 1).gID
              CanCreateGroup = False
              End If
              If CanCreateGroup = True Then                                   '��Ҫ�½���
              GROUP_POINTER = GROUP_POINTER + 1
              pixel(i, j).gID = GROUP_POINTER                                   '�½����ID
              End If
       End If
       Next j
Next i

ReDim IdenPoint(1 To GROUP_POINTER) As TV_2DVECTOR
Dim GroupPointCount() As Long
ReDim GroupPointCount(1 To GROUP_POINTER) As Long                              '���ڵĵ���
For i = 1 To PW
       For j = 1 To PH
       If pixel(i, j).gID <> 0 Then                                                                             '��������Ѿ�����
       IdenPoint(pixel(i, j).gID).x = IdenPoint(pixel(i, j).gID).x + Val(i)             '���ص������ۼ� ֮��һ���͵õ�ƽ����������
       IdenPoint(pixel(i, j).gID).y = IdenPoint(pixel(i, j).gID).y + Val(j)
       GroupPointCount(pixel(i, j).gID) = GroupPointCount(pixel(i, j).gID) + 1 'ͳ�����ڵ���
       End If
       Next j
Next i



'��������������������ʶ�㡪����������
TV.Clear
scr.Draw_Texture GetTex("Measure"), 0, 0, WindowWidth, WindowHeight
For i = 1 To GROUP_POINTER
IdenPoint(i).x = (IdenPoint(i).x / GroupPointCount(i))
IdenPoint(i).y = IdenPoint(i).y / GroupPointCount(i)

'windowwidth/PW�Ǵ�ͼƬ���浽��Ļ������ת��ϵ��
scr.Draw_FilledCircle IdenPoint(i).x * (WindowWidth / PW), IdenPoint(i).y * (WindowHeight / PH), 3, 20, RGBA(1, 0, 0, 1)
Next i
IdenPointCount = GROUP_POINTER '��ʶ����
'����������������������������������������


'����������������ʶ�򡪡�����������������
Dim RectLeft As Long, RectRight As Long, RectTop As Long, RectBottom As Long
RectLeft = PictureWidth
RectRight = 0
RectTop = PictureHeight
RectBottom = 0 '��ֵ
For i = 1 To GROUP_POINTER
'���ɱ�ʶ���� ����9����ı߽�ֵ
If IdenPoint(i).x < RectLeft Then RectLeft = IdenPoint(i).x
If IdenPoint(i).x > RectRight Then RectRight = IdenPoint(i).x
If IdenPoint(i).y < RectTop Then RectTop = IdenPoint(i).y
If IdenPoint(i).y > RectBottom Then RectBottom = IdenPoint(i).y
Next i

 '100mm�˱���  ʵ�ʿ��Ӹ߶�
 '����100mm�ǾŹ���ı߳� ������Ƭ��������ĵ����е�
RealVisibleWidth = 100 * PictureWidth / (RectRight - RectLeft)
RealVisibleHeight = 100 * PictureHeight / (RectBottom - RectTop)


'��ʶ���α߳�
Dim RectP1 As TV_2DVECTOR, RectP2 As TV_2DVECTOR
RectP1 = Vector2(RectLeft * (WindowWidth / PW), RectTop * (WindowHeight / PH))
RectP2 = Vector2(RectRight * (WindowWidth / PW), RectBottom * (WindowHeight / PH))
ScrText.NormalFont_DrawText "��ʶ����: " & CStr(RectRight - RectLeft) & " x " & CStr(RectBottom - RectTop), 10, 50, RGBA(0, 1, 1, 1), 1
'����ʶ����
scr.Draw_Box RectP1.x, RectP1.y, RectP2.x, RectP2.y
'���
TV.RenderToScreen
End Sub



Function GetIdenPoint(ID As Integer) As TV_2DVECTOR
GetIdenPoint = IdenPoint(ID)
End Function
Function GetIdenPointCount() As Integer  '��ȡ��ʶ�����
GetIdenPointCount = IdenPointCount
End Function

Function GetVisibleAngleHorizontal() As Single
Dim hFocalLength As Single
hFocalLength = GetFocalLength '��EXIF�ж�ȡ
Dim a As Single, b As Single, f As Single
a = 36 / 1.59 '1.59��Ч���� �Ǹ�ʲô��135��Ƭ�ɵı�����ϵ
b = RealVisibleWidth
f = hFocalLength
GetVisibleAngleHorizontal = 2 * Math.ATan(a * b / (2 * f * (a + b))) * 180 / 3.1415926
End Function

Function GetVisibleAngleVertical() As Single
Dim vFocalLength As Single
vFocalLength = GetFocalLength '��EXIF�ж�ȡ
Dim a As Single, b As Single, f As Single
a = 24 / 1.59
b = RealVisibleHeight
f = vFocalLength
GetVisibleAngleVertical = 2 * Math.ATan(a * b / (2 * f * (a + b))) * 180 / 3.1415926 '���û��ǽǶ���
End Function

Function GetStandardDepth() As Single
Dim FocalLength As Single
 '��EXIF�ж�ȡ
FocalLength = GetFocalLength

Dim a As Single, b As Single, C1 As Single, C2 As Single
a = 36 / 1.59 'EOS�й��Ƭ�Ŀ��� 1.59���ⲿ���ӵĵ�Ч����ת������
b = RealVisibleWidth
C1 = (1 + (b / a)) * FocalLength
a = 24 / 1.59
b = RealVisibleHeight
C2 = (1 + (b / a)) * FocalLength
GetStandardDepth = (C1 + C2) / 2
End Function

'Function GetImageDistance(dFocalLength As Single) As Single
'Dim a As Single, b As Single, C1 As Single, C2 As Single
'a = 36 / 1.6
'b = RealVisibleWidth
'C1 = (1 + (a / b)) * dFocalLength
'GetImageDistance = C1
'End Function





'��������������������������������ͨ�š�����������������������


Function InitSerialPort(SpecificPortID As Integer, Optional TryOtherWhenError As Boolean = True) As Boolean
Dim s As Long
s = SpecificPortID - 1
Set MSComm1 = New MSComm ' CreateObject("MSCommLib.MSComm")

RetryMark:
On Error Resume Next
s = s + 1 '��һ����
MSComm1.CommPort = Val(s)
MSComm1.Settings = "9600,N,8,1" '�����������ʣ���żλУ��(?)��8λ����λ��1λֹͣλ
MSComm1.PortOpen = True
'��������
If TryOtherWhenError = True And s < 15 And Err.Number <> 0 Then
Err.Clear
GoTo RetryMark:
End If

'����ֵ
If Err.Number = 0 Then
InitSerialPort = True
Else
InitSerialPort = False
End If

End Function

Sub TakePhoto_START()
MSComm1.OutBufferCount = 0 '�������Ĵ���
MSComm1.Output = "1"
End Sub

Sub TakePhoto_END()
MSComm1.OutBufferCount = 0 '�������Ĵ���
MSComm1.Output = "0"
End Sub





'������������������������EXIF����������������������������
Function GetFocalLength() As Single
Set JPGInfoReader = New ExifReader
JPGInfoReader.Load App.Path & "\Group\Measure.jpg"
GetFocalLength = Val(Left(JPGInfoReader.Tag(FocalLength), 2))
End Function