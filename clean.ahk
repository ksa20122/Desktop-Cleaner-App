#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Force
DetectHiddenWindows, On
SetBatchLines, -1

; #################### معلومات التطبيق ####################
CurrentVersion := "1.0" ; <--- قم بزيادة هذا الرقم مع كل تحديث جديد (مثلاً 1.1)
AppName := "DesktopCleaner.exe" ; اسم الملف التنفيذي
TaskName := "Smart Desktop Cleaner Task" ; اسم المهمة المجدولة

; --- طلب صلاحيات المسؤول ---
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; #################### الجزء الذكي لإنشاء المهمة ####################
RunWait, schtasks /query /TN "%TaskName%", , Hide
if (ErrorLevel)
{
    Command := "schtasks /create /TN """ . TaskName . """ /TR ""'" . A_ScriptFullPath . "'"" /SC ONLOGON /RL HIGHEST /F"
    Run, %ComSpec% /c %Command%, , Hide
    MsgBox, 64, , تم إعداد المنظف الذكي بنجاح!`nسيتم الآن تشغيل الأداة تلقائيًا في الخلفية عند كل مرة تسجل فيها الدخول إلى ويندوز.
}

; #################### قائمة أيقونة شريط المهام ####################
Menu, Tray, NoStandard
Menu, Tray, Add, &تنظيف سطح المكتب (Shift+F2), RunCleanerGui
Menu, Tray, Add
Menu, Tray, Add, البحث عن تحديثات, CheckForUpdates
Menu, Tray, Add, &خروج, ExitApp
Return ; مهم جدًا لوقف التنفيذ التلقائي بعد هذا الجزء

RunCleanerGui:
    Send, +{F2}
Return

ExitApp:
    ExitApp
Return

; #################### قسم منظف سطح المكتب ####################
+F2::
    ; قائمة الاستثناءات
    ExcludeList = هذا الكمبيوتر الشخصي,سلة المحذوفات,file.bru,العاب,تراينرز,سطح المكـتب,البرامج,العمل,مؤقت,سكربتات,غير مهم
    ExcludeList .= "," . A_ScriptName

    ; مجلدات الهدف والنسخ الاحتياطي
    DestFolder := A_Desktop "\غير مهم"
    BackupFolder := A_Desktop "\نسخة_احتياطية"
    LogsFolder := A_ScriptDir "\Logs"
    FileCreateDir, %DestFolder%
    FileCreateDir, %BackupFolder%
    FileCreateDir, %LogsFolder%

    ItemsToMove := ""

    ; البحث في سطح المكتب الشخصي والعام
    Loop, Files, %A_Desktop%\*, FD
        AddIfNotExcluded(A_LoopFileFullPath, A_LoopFileName, ExcludeList, ItemsToMove)
    Loop, Files, %A_DesktopCommon%\*, FD
        AddIfNotExcluded(A_LoopFileFullPath, A_LoopFileName, ExcludeList, ItemsToMove)

    if (ItemsToMove = "")
    {
        MsgBox, 64, , كل شيء منظم! لم يتم العثور على أي عناصر للنقل.
        return
    }

    ; إنشاء GUI
    Gui, New, +Resize +AlwaysOnTop, تأكيد النقل
    Gui, Add, Text,, سيتم نقل الملفات التالية:
    Gui, Add, ListView, vFileList w500 h300 Checked Grid, اسم الملف|الحجم (KB)
    
    Loop, Parse, ItemsToMove, `n
    {
        if (A_LoopField = "")
            continue
        ItemParts := StrSplit(A_LoopField, "|")
        CurrentPath := ItemParts[1], CurrentName := ItemParts[2]
        FileGetSize, SizeBytes, %CurrentPath%
        SizeKB := Round(SizeBytes/1024, 1)
        LV_Add("", CurrentName, SizeKB)
    }

    Gui, Add, Button, gSelectAll, تحديد الكل
    Gui, Add, Button, gUnselectAll, إلغاء التحديد
    Gui, Add, Button, gStartMove, بدء النقل
    Gui, Add, Button, gCancel, إلغاء
    Gui, Add, Progress, vProgressBar w500 h20
    Gui, Show,, تأكيد النقل
Return

SelectAll:
    LV_Modify(0, "Check")
Return

UnselectAll:
    LV_Modify(0, "UnCheck")
Return

StartMove:
    Gui, Submit
    TotalItems := LV_GetCount()
    SuccessCount := 0, FailCount := 0, SessionLog := LogsFolder "\Log_" A_Now ".txt"
    Loop, Parse, ItemsToMove, `n
    {
        if (A_LoopField = "")
            continue
        ItemParts := StrSplit(A_LoopField, "|"), FullPath := ItemParts[1], ItemName := ItemParts[2]
        Found := false
        Loop, %TotalItems%
        {
            LV_GetText(Name, A_Index, 1)
            if (Name = ItemName)
            {
                if (LV_GetNext(A_Index - 1, "Checked") = A_Index)
                    Found := true
                break
            }
        }
        if not Found
            continue

        FinalDestPath := DestFolder "\" . ItemName, FinalLogName := ItemName
        if FileExist(FinalDestPath)
        {
            SplitPath, ItemName, , , OutExtension, OutNameNoExt
            Loop
            {
                if (OutExtension = "")
                    TestName := ItemName . " (" . A_Index . ")"
                else
                    TestName := OutNameNoExt . " (" . A_Index . ")." . OutExtension
                
                TestPath := DestFolder "\" . TestName
                if not FileExist(TestPath)
                {
                    FinalDestPath := TestPath, FinalLogName := TestName
                    break
                }
            }
        }
        FileCopy, %FullPath%, %BackupFolder%\%ItemName%, 1
        FileGetAttrib, Attributes, %FullPath%
        if InStr(Attributes, "D")
            FileMoveDir, %FullPath%, %FinalDestPath%, 0
        else
            FileMove, %FullPath%, %FinalDestPath%
        if ErrorLevel
            FailCount += 1
        else
            SuccessCount += 1
        Progress := Round((A_Index / TotalItems) * 100)
        GuiControl,, ProgressBar, %Progress%
        Status := (ErrorLevel ? "فشل" : "تم النقل")
        FileAppend, %A_Now% - %FinalLogName% - %Status%`n, %SessionLog%
    }
    Gui, Destroy
    TrayTip, النقل, انتهت العملية.`nتم نقل %SuccessCount% عنصر بنجاح.`nفشل نقل %FailCount% عنصر., 5
    SoundBeep, 1000, 500
    Sleep, 500
    WinActivate, ahk_class Progman
    Sleep, 100
    Send, {F5}
Return

Cancel:
    Gui, Destroy
Return

AddIfNotExcluded(FullPath, FileName, ExcludeList, ByRef Items)
{
    IsExcluded := false
    Loop, Parse, ExcludeList, `,
    {
        if (FileName = Trim(A_LoopField))
        {
            IsExcluded := true
            break
        }
    }
    if not IsExcluded
        Items .= FullPath "|" FileName "`n"
}


; #################### قسم التحديث الأونلاين ####################
CheckForUpdates:
    ; ######### ضع روابطك المباشرة هنا #########
    VersionURL := "https://raw.githubusercontent.com/YourUsername/YourRepoName/main/version.txt"
    InstallerURL := "https://github.com/YourUsername/YourRepoName/releases/download/v1.0/setup.exe"
    ; ###########################################

    TrayTip, , جاري البحث عن تحديثات..., 10, 1
    UrlDownloadToFile, %VersionURL%, version_temp.txt
    if (ErrorLevel)
    {
        MsgBox, 16, خطأ, لم أتمكن من الاتصال بالخادم. الرجاء التحقق من اتصالك بالإنترنت.
        FileDelete, version_temp.txt
        return
    }

    FileRead, LatestVersion, version_temp.txt
    FileDelete, version_temp.txt
    LatestVersion := Trim(LatestVersion)

    if (LatestVersion > CurrentVersion)
    {
        MsgBox, 36, تحديث متوفر!, يوجد إصدار جديد (%LatestVersion%) متوفر.`nهل ترغب في تحميله وتثبيته الآن؟
        IfMsgBox, No
            return
        
        TrayTip, , جاري تحميل التحديث... قد يستغرق هذا بعض الوقت., 10, 1
        UrlDownloadToFile, %InstallerURL%, %A_Temp%\NewUpdate.exe
        if (ErrorLevel)
        {
            MsgBox, 16, خطأ, فشل تحميل ملف التحديث. الرجاء المحاولة مرة أخرى.
            FileDelete, %A_Temp%\NewUpdate.exe
            return
        }

        TrayTip, , اكتمل التحميل! سيتم الآن تشغيل المثبت., 10, 1
        Sleep, 2000
        Run, %A_Temp%\NewUpdate.exe
        ExitApp
    }
    else
    {
        MsgBox, 64, , أنت تستخدم أحدث إصدار بالفعل!
    }
Return