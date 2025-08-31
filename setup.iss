; ===================================================================
;  Inno Setup Script for "Smart Desktop Cleaner"
; ===================================================================

; ###################################################################
; #                  قسم الإعدادات الرئيسية (عدّل هنا)                 #
; ###################################################################

#define MyAppName "منظف سطح المكتب الذكي"
#define MyAppVersion "1.0"
#define MyAppPublisher "اسمك أو اسم فريقك"
#define MyAppURL "رابط مستودع GitHub الخاص بك"
#define MyAppExeName "clean.exe"
#define TaskName "Smart Desktop Cleaner Task"

; ###################################################################
; #                          قسم الإعداد [Setup]                        #
; ###################################################################

[Setup]
; AppId: رقم تعريفي فريد لتطبيقك. لا تغيره.
AppId={{C1B9A317-15E8-4A5C-A4A6-2E1F0C2F7C2B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
; DefaultDirName: المجلد الافتراضي الذي سيتم تثبيت البرنامج فيه.
DefaultDirName={autopf}\{#MyAppName}
; DisableProgramGroupPage: لتعطيل صفحة "مجلد قائمة ابدأ" في معالج التثبيت.
DisableProgramGroupPage=yes
; OutputDir: المجلد الذي سيتم حفظ ملف setup.exe النهائي فيه.
OutputDir=.\Output
OutputBaseFilename=setup-cleaner-v{#MyAppVersion}
; Compression: أفضل ضغط لتقليل حجم ملف التثبيت.
Compression=lzma
SolidCompression=yes
; WizardStyle: النمط الحديث لواجهة التثبيت.
WizardStyle=modern
; PrivilegesRequired: ضروري لضمان أن المثبت يعمل بصلاحيات المسؤول.
PrivilegesRequired=admin

; ###################################################################
; #                         قسم اللغات [Languages]                      #
; ###################################################################

[Languages]
; هذا السطر يضيف اللغة العربية لواجهة التثبيت.
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

; ###################################################################
; #                         قسم المهام [Tasks]                        #
; ###################################################################

[Tasks]
; هذا السطر يضيف خيار "إنشاء أيقونة على سطح المكتب" أثناء التثبيت.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

; ###################################################################
; #                        قسم الملفات [Files]                         #
; ###################################################################

[Files]
; المصدر (Source): هذا هو السطر الذي تم تعديله بناءً على طلبك.
Source: "C:\8\clean.exe"; DestDir: "{app}"; Flags: ignoreversion

; ###################################################################
; #                       قسم الأيقونات [Icons]                       #
; ###################################################################

[Icons]
; أيقونة البرنامج في قائمة ابدأ
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; أيقونة البرنامج على سطح المكتب (إذا اختار المستخدم ذلك)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

; ###################################################################
; #                    قسم أوامر التشغيل [Run]                       #
; ###################################################################

[Run]
; هذا القسم يعمل في نهاية التثبيت (مهم جدًا للتحديثات)

; 1. إيقاف أي نسخة قديمة تعمل حاليًا قبل تشغيل الجديدة
Filename: "taskkill"; Parameters: "/F /IM {#MyAppExeName}"; Flags: runhidden

; 2. تشغيل النسخة الجديدة مباشرة بعد التثبيت ليقوم بإنشاء المهمة المجدولة
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; ###################################################################
; #            قسم أوامر إلغاء التثبيت [UninstallRun]             #
; ###################################################################

[UninstallRun]
; هذا القسم يعمل عند إلغاء تثبيت البرنامج (مهم جدًا للتنظيف الكامل)

; 1. إيقاف البرنامج إذا كان يعمل قبل حذفه
Filename: "taskkill"; Parameters: "/F /IM {#MyAppExeName}"; Flags: runhidden

; 2. حذف المهمة المجدولة لضمان عدم ترك أي أثر للبرنامج
Filename: "schtasks"; Parameters: "/delete /TN ""{#TaskName}"" /F"; Flags: runhidden