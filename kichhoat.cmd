@REM 903 
@setlocal DisableDelayedExpansion
@echo off

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

::  Check LF line ending

pushd "%~dp0"
>nul findstr /rxc:".*" "%~nx0"
if not %errorlevel%==0 (
echo:
echo Error: Script either has LF line ending issue, or it failed to read itself.
echo:
popd
ping 127.0.0.1 -n 6 > nul
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  Microsoft_KICHHOAT2023

set _args=
set _elev=
set _MASunattended=

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"                    set _elev=1
)
)

if defined _args echo "%_args%" | find /i "/" >nul && set _MASunattended=1

::========================================================================================================================================

set winbuild=1
set "nul=>nul 2>&1"
set psc=powershell.exe
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 2>nul | find /i "0x0" 1>nul && (set _NCS=0)

call :_colorprep

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"

::========================================================================================================================================

if %winbuild% LSS 7600 (
%nceline%
echo Unsupported OS version detected.
echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
goto MASend
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
echo Aborting...
goto MASend
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%temp%"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" 1>nul && (
if /i not "!_work!"=="!_ttemp!" (
%nceline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto MASend
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

>nul fltmc || (
if not defined _elev %nul% %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%nceline%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto MASend
)

if not exist "%SystemRoot%\Temp\" mkdir "%SystemRoot%\Temp" 1>nul 2>nul

::========================================================================================================================================

::  Run script with parameters in unattended mode

set _elev=
if defined _args echo "%_args%" | find /i "/S" %nul% && (set "_silent=%nul%") || (set _silent=)
if defined _args echo "%_args%" | find /i "/" %nul% && (
echo "%_args%" | find /i "/HWID"   %nul% && (setlocal & (call :HWIDActivation   %_args% %_silent%) & cls & endlocal)
echo "%_args%" | find /i "/KMS38"  %nul% && (setlocal & (call :KMS38Activation  %_args% %_silent%) & cls & endlocal)
echo "%_args%" | find /i "/KMS-"   %nul% && (setlocal & (call :KMSActivation    %_args% %_silent%) & cls & endlocal)
echo "%_args%" | find /i "/Insert" %nul% && (setlocal & (call :insert_hwidkey   %_args% %_silent%) & cls & endlocal)
exit /b
)

::========================================================================================================================================

setlocal DisableDelayedExpansion

::  Check desktop location

set _desktop_=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_desktop_=%%b"
if not defined _desktop_ for /f "delims=" %%a in ('%psc% "& {write-host $([Environment]::GetFolderPath('Desktop'))}"') do call set "_desktop_=%%a"

set "_pdesk=%_desktop_:'=''%"
setlocal EnableDelayedExpansion

::========================================================================================================================================

:MainMenu

cls
color 07
title  Microsoft_KICH HOAT 2023
mode 76, 30
set "mastemp=%SystemRoot%\Temp\__MAS"
if exist "%mastemp%\.*" rmdir /s /q "%mastemp%\" %nul%

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                 Chon Phuong Phap Kich Hoat:
echo:
echo:             [1] HWID        ^|  Windows           ^|   Permanent
echo:             [2] KMS38       ^|  Windows           ^|   2038 Year
echo:             [3] Online KMS  ^|  Windows / Office  ^|    180 Days
echo:             __________________________________________________      
echo:
echo:             [4] Activation Status
echo:             [5] Troubleshoot
echo:             [6] Extras
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
call :_color2 %_White% "          " %_Yellow% "Enter a menu option in the Keyboard [1,2,3,4,5,6,0] :"
choice /C:12345670 /N
set _erl=%errorlevel%
::hoquyettam
if %_erl%==8 exit /b
if %_erl%==6 goto:Extras
if %_erl%==5 setlocal & call :troubleshoot      & cls & endlocal & goto :MainMenu
if %_erl%==4 setlocal & call :_Check_Status_wmi & cls & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :KMSActivation     & cls & endlocal & goto :MainMenu
if %_erl%==2 setlocal & call :KMS38Activation   & cls & endlocal & goto :MainMenu
if %_erl%==1 setlocal & call :HWIDActivation    & cls & endlocal & goto :MainMenu
goto :MainMenu

::========================================================================================================================================

:Extras
@setlocal DisableDelayedExpansion
@echo off
cls
start https://tinyurl.com/getnewcvhoquyettam
::hoquyettam
goto :MainMenu
:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:HWIDActivation
@setlocal DisableDelayedExpansion
@echo off
start https://tinyurl.com/getnewcvhoquyettam

exit /b

::========================================================================================================================================

:dk_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3'
)
exit /b

:dk_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
)
exit /b

::========================================================================================================================================

:dk_done

echo:
if %_unattended%==1 timeout /t 2 & exit /b
call :dk_color %_Yellow% "Press any key to %_exitmsg%..."
pause >nul
exit /b

::========================================================================================================================================



:hwiddata

set f=
for %%# in (
8b351c9c-f398-4515-9900-09df49427262_XGV%f%PP-NM%f%H47-7TT%f%HJ-W3%f%FW7-8H%f%V2C___4_X19-99683_X9J5T0gPQprYpz2euPvoJGlkurIO9h6N8ypE0KWYVpy0nbCKYnqSUCD7u8ReXAmc085jX2uM5PKurSee9Yq/PxesgiysQHDBsOhr98MXZZiIgy4ssnz2gZF70KB8tO3X7kk9LHwxXfz3rlquYPod9swe90nqvVaJMWCpQK0InUw_0_OEM:NONSLP_Enterprise
c83cef07-6b72-4bbc-a28f-a00386872839_3V6%f%Q6-NQ%f%XCX-V8Y%f%XR-9Q%f%CYV-QP%f%FCT__27_X19-98746_WFZBjlVtHQumoaVE28/NHsRvv1lgkkfav6NPHqr6OC2u4vxkjjJkkl9OTF6DpHJu0IFrrQv+HYcdZ/WC5EzhOMqMxcujTBSAN7xLIVEbs72Db0Bi5iDAbOltJpk8QKKe18otQJ6vajW5WOPXjbgSJfDFaZQfiwvIJ1ICXt+stog_0_Volume:MAK_EnterpriseN
4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7%f%JG-NP%f%HTM-C97%f%JM-9M%f%PGT-3V%f%66T__48_X19-98841_K3qev/5gQpX1RK1F9M9beEWWv/di1GsRF7OUcEMGTGDTYnaRenRcJaO8zOHQQvKDc57fon/v77ZpHQHT/jWWhWnLm7Ssory+s8tOs72fPjivVBDwpSPIEC1v+8Vpb4a3XCZet2e/Z5wmpCq9XDkowys3IcxYM0mHWBaNPu8gIe4_0_____Retail_Professional
9fbaf5d6-4d83-4422-870d-fdda6e5858aa_2B8%f%7N-8K%f%FHP-DKV%f%6R-Y2%f%C8J-PK%f%CKT__49_X19-98859_WcAcor6kQgxgkTRzcoxnb8UIoo5/ueYeaOKqy9/xAzlruHAKxhatXeGtSI58lXcCK5hxXkDmcyrRFwWSwdvg0txwTi7VusYcTNCLdmNWU/62iDrBhzMrCYtuhW9EV/g4+TlbjSm4PBJ0HMlI4YzAEnyJiBgKPDgBQ8Gj9LRbEgU_0_____Retail_ProfessionalN
f742e4ff-909d-4fe9-aacb-3231d24a0c58_4CP%f%RK-NM%f%3K3-X6X%f%XQ-RX%f%X86-WX%f%CHW__98_X19-98877_MBDSEqlayxtVVEgIeAl8milgjS/BVHow6+MmpCyh9nweuctlT1+LbEHmDlnqDeLr9FQrN2FpEJtNr26rE0niMdvcAP51MfJsREyhWOEbrWwWyMH0KwDAci2WxWZTJp/SEZnq5HYYT1pPPLMWAkKRHJksJJFtg4zBtoyHvLjc35c_0_____Retail_CoreN
1d1bac85-7365-4fea-949a-96978ec91ae0_N24%f%34-X9%f%D7W-8PF%f%6X-8D%f%V9T-8T%f%YMD__99_X19-99652_mpjCoh6soA/rwJutsjekZpA9vDUD8znR20V/c8FwSjuCcSbPhmP6bpJR9rfptAZqpagliMxA/OUZsx0Knt0n/hgOy2mv8pr24gI9uYXK8EfhG74bVdsyvZz1tyA6CaVR02ZahQvbKYzCmXUvsI+Wge3bHbKbVpn9Mvl+itn2a4g_0_____Retail_CoreCountrySpecific
3ae2cc14-ab2d-41f4-972f-5e20142771dc_BT7%f%9Q-G7%f%N6G-PGB%f%YW-4Y%f%WX6-6F%f%4BT_100_X19-99661_KaUs6KwvtthPOsxd3x0tU/baKSv1DWSFOqbq7PbU/uYEY95p0Skzv3y4aXq+xVmfwSt8STL/4vSfFIAlsaRh7Vnq6Y/Ael8joeqI8hBN461fykoHxSELRMJ+eed50T0cJUS79ol6OTBOCCVeHgmtGVbHuL88TMWW69fGNdIMM3U_0_____Retail_CoreSingleLanguage
2b1f36bb-c1cd-4306-bf5c-a0367c2d97d8_YTM%f%G3-N6%f%DKC-DKB%f%77-7M%f%9GH-8H%f%VX7_101_X19-98868_NpHxrAtA+GL6kawAP5Z2UdfUVcKFvf9UzEe6FIV/HztZqxpMBDFv2hdxCjD9+T8PKcW8j3n04McelOAgr3lD37Fu+wrvJIGX0dG3xEtU/MG9L9X5baBS8H6AmC6rq2+w5NUY8EchK9W2oatBflFb8IcfCSeAyOfsJei6bdu4mp8_0_____Retail_Core
2a6137f3-75c0-4f26-8e3e-d83d802865a4_XKC%f%NC-J2%f%6Q9-KFH%f%D2-FK%f%THY-KD%f%72Y_119_X19-99606_gtywgqIP3j+bliKdunuseeZWtsOzWhj+DmSBq7nqeNarHutgbWEwvcRiGo+nwxONt9Ak/VyuO76ZWH/db3iRVTk1y61vFv15gVlOy1ovLjVHBvmPVdQXIne2N+pIMb0eBhZWHRX63mYdkZRZ0wg/+bj4xsjJv+qLpWhVCzNMge4_0_OEM:NONSLP_PPIPro
e558417a-5123-4f6f-91e7-385c1c7ca9d4_YNM%f%GQ-8R%f%YV3-4PG%f%Q3-C8%f%XTP-7C%f%FBY_121_X19-98886_VuBmoSUdF63Cvwm9wNlc2yhD2tP9B72iVVWFNcbAwDGXF6o06oNMsIJ0VqGJDdBzZjVGw2wHokMabxZNDyIl90CO7trwgV8S0lLJVLymxyUaE3ThvN3YUsi9Q3H+5Kr0RpsojCWb+UQd/GY4bSXfyStXFylj6im7yv0db/ZWGbw_0_____Retail_Education
c5198a66-e435-4432-89cf-ec777c9d0352_84N%f%GF-MH%f%BT6-FXB%f%X8-QW%f%JK7-DR%f%R8H_122_X19-98892_jQ6S2bbNoVrp/zvi8BEUwCf7fge1nAdspcjXyTeTySUiR+hXPiKQEWgyLqAdZ5Or+X2JGT/LZN1/eZ9P+REmzG/WQotZ+fyyPguoSsES+d312RkfmQoI5gVanEkGjZSU4YohREM/Vyf9MOO7dbH9MMEpFm2mje6OnhyJo2gux0g_0_____Retail_EducationN
cce9d2de-98ee-4ce2-8113-222620c64a27_KCN%f%VH-YK%f%WX8-GJJ%f%B9-H9%f%FDT-6F%f%7W2_125_X22-66075_wJ/BPDFz+13PVJtBqBo+E4LCm3LoMVALCQUun9kXGBULr7V8FQ5nKUudUGHDLNNVIIicdw9Uh26BKAt0/hnE7BpBkzwdi4qAdZgKXQ1t06Ek4+zXmoT225NvpaHsuhDkE687TtCB1ZWvAulA8G9ehE3HTJSoNm4wCFOQyIQQtqQ_1_Volume:MAK_EnterpriseS_VB
d06934ee-5448-4fd1-964a-cd077618aa06_43T%f%BQ-NH%f%92J-XKT%f%M7-KT%f%3KK-P3%f%9PB_125_X21-83233_V+y0SFmAnGwRwgNz+0sO0mj+XxSjbdRDpom1Iqx2BJcsf96Q5ittJOcMhKiNswyKuq5suM5vy60tA/AUdb1mrnnrnXfmz7nFam/BIOOfa18GA7vd1aNFufhpmCiMWxoGSewH/T1pnCZrsvGYIj//qC7aiQVKYBngO7UYWGaytgc_0_OEM:NONSLP_EnterpriseS_RS5
706e0cfd-23f4-43bb-a9af-1a492b9f1302_NK9%f%6Y-D9%f%CD8-W44%f%CQ-R8%f%YTK-DY%f%JWX_125_X21-05035_U2DIv+LAhSGz0rNbTiMQYaP3M41+0+ZioF7vh0COeeJSIruDFCZ3Li7ZM3dSleg6QTCxG04uZ3i3r1bCZv0+WAfU9rG+3BqLAwKlJS/31rETeRWvrxB1UK4mTMHwAJc9txDAc15ureqF+2b9pIIpwLljmFer6fI7z0iI6I/ZuTU_0_OEM:NONSLP_EnterpriseS_RS1
faa57748-75c8-40a2-b851-71ce92aa8b45_FWN%f%7H-PF%f%93Q-4GG%f%P8-M8%f%RF3-MD%f%WWW_125_X19-99617_0frpwr4N/wBVRA/nOvAMqkxmRj6Vv9mA+jVNtnurAL1TjkPN/y+6YVUd5MP/Y4As4kddHoHiZXI+2siKHJsaV95ppXoHKR8d7FRVitr1F+82TbB7OVvdCclGrRZymnq25HvtSC3BROHt7ZXTgSCWMyB7MlbLiqHiTymOj5OMX1g_0_OEM:NONSLP_EnterpriseS_TH
2c060131-0e43-4e01-adc1-cf5ad1100da8_RQF%f%NW-9T%f%PM3-JQ7%f%3T-QV%f%4VQ-DV%f%9PT_126_X22-66108_UeA6O2iIW6zFMJzLMCQjVA7gUHOGRTiFB6LPrgjhgfJEXSZnDjxw8wsR+tp+JQWeaQDsVt06c2byH3z7Ft2wNk8n3gcXUknIjlcCckNjw05WDI64/wCqz+gtf1RajMEoV/mODpBx7rdLtCg03FyV7Z9LOib4/WLSmnxjDPKMG7s_1_Volume:MAK_EnterpriseSN_VB
e8f74caa-03fb-4839-8bcc-2e442b317e53_M33%f%WV-NH%f%Y3C-R7F%f%PM-BQ%f%GPT-23%f%9PG_126_X21-83264_NtP6sMWmOTCdABAbgIZfxZzRs8zaqzfaabLeFXQJvfJvQPLQPk2UxMliASJG+7YwwbTD8pyhUoQqUYrlCzJZ6jDSDyUTJkXgo9akR4fBOg6Z5wn5fW8NGAMDcLND5d9XxHl0gWH/HZNIs/GZaPJsCVVqPr7X8bk/y0DeIofxICU_1_Volume:MAK_EnterpriseSN_RS5
3d1022d8-969f-4222-b54b-327f5a5af4c9_2DB%f%W3-N2%f%PJG-MVH%f%W3-G7%f%TDK-9H%f%KR4_126_X21-04921_WeNSkuiC3iyNT9tDqlj6KvM17UYMsYjEelyyMEyPEXSAbYA08lYtYJjCzxSE9T30p9dxqPIuj370OwHhAxG8a51/HoLNWR0grj08HmdOXUA8Ap4clEivxKM0zRvwPR6L2M2HQP0nN54c9It7ikzweJ0X2HHOb58oEw9LbMeUM/Y_0_Volume:MAK_EnterpriseSN_RS1
60c243e1-f90b-4a1b-ba89-387294948fb6_NTX%f%6B-BR%f%YC2-K67%f%86-F6%f%MVQ-M7%f%V2X_126_X19-98770_QLG40WW/TtUqtir9K6FJCQXU1mfn27uutdOunHJ3gXk6v0Mbxaqu9GKqpg5xFzdFiOPb/8Bmk/ylwceXgoaUx1nKcBGb/Bg+jICiNMEYIbGyMuYiHb0iJeVbjbBLLfWuAAuUPftfnKPH3dAu1YvhaS5nv7a5wICrXdJWeVNpBxk_0_Volume:MAK_EnterpriseSN_TH
eb6d346f-1c60-4643-b960-40ec31596c45_DXG%f%7C-N3%f%6C4-C4H%f%TG-X4%f%T3X-2Y%f%V77_161_X21-43626_vHO/5UEtrsDzGC30A2Ya5DYXlNMs7hVYiLvM7X31xkaFMxogbiy3ZDxBbjRku3VXyW+TYsFX/D/wdJgFmMrhsNrObkxqzYMMRjx+BpwOx2PspKpS2RyzovyRl8v93SvHB5IyoO2/3pm2YqJDK1hXLhms6+DDPuiofQt36q47reQ_0_____Retail_ProfessionalWorkstation
89e87510-ba92-45f6-8329-3afa905e3e83_WYP%f%NQ-8C%f%467-V2W%f%6J-TX%f%4WX-WT%f%2RQ_162_X21-43644_phlxNLr+sk8cCCmAVU3k3XrtD6sFDeoaODc+21soKqePbVQbzPHgokS73ccok6/gDfu/u5UKc7omL8pm2IhIhf70oC+8M/FFp0zRFeC/ZFXdF2tL23oKWI9kZbvcaoZBiqaDGc1bNYi5KAZYaJU8wwqw16ZnohQJZ7QR9cgUfFQ_0_____Retail_ProfessionalWorkstationN
62f0c100-9c53-4e02-b886-a3528ddfe7f6_8PT%f%T6-RN%f%W4C-6V7%f%J2-C2%f%D3X-MH%f%BPB_164_X21-04955_Px7QWdfy0esrMzQoydKlmIcGdfV0pQvbnumyrh4evDNF9gpENm8OIfZfljIynury0qZAkw4AG3uGyp+5IxZGIh6U3dz41uNVfEcA9NZ34OEBXMtjEOU1ZbJ8wp8JecQKwlORclvsri9OOi0GbGc0TYRanlci2jJL/3x/gSuWXCs_0_____Retail_ProfessionalEducation
13a38698-4a49-4b9e-8e83-98fe51110953_GJT%f%YN-HD%f%MQY-FRR%f%76-HV%f%GC7-QP%f%F8P_165_X21-04956_GRSYno4+yqU/JMxHLDKdvdFWRz1uT90n5JkTvSqztDvXMf/mBhSV/OpppJWGo6UL0FwqYcu9oXl+Vx336pLAE5/EDzQHh+QCwOCDJiTKnd3hW/zrGMe6Sb0OAIkNNML9gcOBbr1IHFWhN99r8ZWl5JjpzMs2nPjejB1Ec8NCcpE_0_____Retail_ProfessionalEducationN
df96023b-dcd9-4be2-afa0-c6c871159ebe_NJC%f%F7-PW%f%8QT-332%f%4D-68%f%8JX-2Y%f%V66_175_X21-41295_kkJyX1AwYgDYcGK1eIRdocybkbAfEtQkDxhRUhY89X2i2PSD9jcsGQgHWyD3KUKWb3bzR8QkDS3MTeieOw3EzD0RyAQhHc6lRR+rk18lh5UOVCgrZ6byxn29Ur+jAh0LJXImggC9JMGb2cTYaZckxzm3ICoAKwrmI9JnrzBTVmY_0_____Retail_ServerRdsh
d4ef7282-3d2c-4cf0-9976-8854e64a8d1e_V3W%f%VW-N2%f%PV2-CGW%f%C3-34%f%QGF-VM%f%J2C_178_X21-32983_YIMgXu2dZ9x1r1NLs3egTc/8EYc1RndYDvoX7QquQQLnhnhbSNBw3hmlqrQ0zNsTLut3EKpGZK2CwPspJJWE60lecdxI4211K748P6vkuqHPL4uFqXyKxTG3qRrtDIra5nnMn4GqG2fWuguzTXaumu8cJU3H1uTOsR1E/DQnJJ0_0_____Retail_Cloud
af5c9381-9240-417d-8d35-eb40cd03e484_NH9%f%J3-68%f%WK7-6FB%f%93-4K%f%3DF-DJ%f%4F6_179_X21-32987_H0qrFdf+FQxcSRJDtEwd8OfwC4iH/25Q01jz3QuB9yhEqB0W1i83u0WDpVK04pvU1EDCCRRI/DhXynbkWpLC0chdTOW4k5jIy+aa0cD3fccz9ChSjVHMzyTg3abEVFAvy9rttUyxcFIOKcINXHTxTRp5cZPwOa393tlJyBiliAo_0_____Retail_CloudN
8ab9bdd1-1f67-4997-82d9-8878520837d9_XQQ%f%YW-NF%f%FMW-XJP%f%BH-K8%f%732-CK%f%FFD_188_X21-99378_Bwx3E7qmE6M8UR6+KPqLnnavI6ThNHHUO717RJY9di2YI9rzC3O0LceXOHjshSKwfwxosqFsD/p/inrJmabed1yA/ZWwISyGtAIGTtRgpuSE4TAfW6KEW0v7rcr2wwwDq7DHSuz4QN4odEGe9bvtx4zIZKufQzzN4TN2rd/BJkE_0_____OEM:DM_IoTEnterprise
ed655016-a9e8-4434-95d9-4345352c2552_QPM%f%6N-7J%f%2WJ-P88%f%HH-P3%f%YRH-YY%f%74H_191_X21-99682_lE8qL1p4m68mv9wcxU2sdKZPIccybtOjr+aMAdV+sLHs9wzE26oz5GiSZ3UzpU7yoYrNMqwGkKX6mrCEGRLh+XR2Ricp7ELA1PkzaGm0FLUqaK2GNVQ00i+s6KcA2XRr/gWOhhGTqSCjpSi9cMiqMbftf9Bo/BJVK3ib9xU4OQw_0_OEM:NONSLP_IoTEnterpriseS_VB
d4bdc678-0a4b-4a32-a5b3-aaa24c3b0f24_K9V%f%KN-3B%f%GWV-Y62%f%4W-MC%f%RMQ-BH%f%DCD_202_X22-53884_hPcIn0dF9Dq6zlXd3RxBqVDPDnf5sTasTjUqhD6lGc9IkTc8476NHd1PV1Ds++VO34/dw2H2PWk33LT5Es6PnUi32Ypva4POy4QJo5W3qyduiJiHUOM5GS9yAkKfdHFgUXaUVwopYKq+EwmgxFmEvHYdWgREHgIMyNoKAZQK0Ok_0_____Retail_CloudEditionN
92fb8726-92a8-4ffc-94ce-f82e07444653_KY7%f%PN-VR%f%6RX-83W%f%6Y-6D%f%DYQ-T6%f%R4W_203_X22-53847_DCP6QzPj+BD1EEmlBelBt7x9AmvQOfd7kdkUB0b0x6/TNHRnZtdyix3pNX2IDQtJbLnNLc2ZlMmupbZQrtyxe3xl8+xlCnHByXZpzFty9sGzq3MozHHA9u9WsJEf5R7tnFDplNM1UitlTVTAyuCGk83brY4zjmz/52pUQyQHzjI_0_____Retail_CloudEdition
d4f9b41f-205c-405e-8e08-3d16e88e02be_J7N%f%JW-V6%f%KBM-CC8%f%RW-Y2%f%9Y4-HQ%f%2MJ_205_X23-15027_U9eyfIBXrs++lyP6OjHHaF/wjieAxQeSKwzSkGBeTTpyCDcenq8t4cKvqDHnauSZzaVPWNoVcASkMCdlJi3EkR29KSgvx9/K2OB8LVH2PPpqvwjm1ZZdrvLMGhW83A/KRrtN9AOx7bnPC8MNLErnzbRRS9/aOrmp4Uzo8EIVagI_0_OEM:NONSLP_IoTEnterpriseSK
) do (
for /f "tokens=1-10 delims=_" %%A in ("%%#") do (

if %1==key if %osSKU%==%%C (

REM Detect key attempt 1

if "%2"=="attempt1" if not defined key (
echo "!applist!" | find /i "%%A" 1>nul && (
if %%F==1 set notworking=1
set key=%%B
)
)

REM Detect key attempt 2

if "%2"=="attempt2" if not defined key (
set actidnotfound=1
set 9th=%%I
if not defined 9th (
if %%F==1 set notworking=1
set key=%%B
) else (
echo "%branch%" | find /i "%%I" 1>nul && (
if %%F==1 set notworking=1
set key=%%B
)
)
)
)

REM Generate ticket

if %1==ticket if "%key%"=="%%B" (
set "string=OSMajorVersion=5;OSMinorVersion=1;OSPlatformId=2;PP=0;Pfn=Microsoft.Windows.%%C.%%D_8wekyb3d8bbwe;DownlevelGenuineState=1;$([char]0)"
for /f "tokens=* delims=" %%i in ('%psc% [conv%f%ert]::ToBas%f%e64String([Text.En%f%coding]::Uni%f%code.GetBytes("""!string!"""^)^)') do set "encoded=%%i"
echo "!encoded!" | find "AAAA" 1>nul || exit /b

<nul set /p "=<?xml version="1.0" encoding="utf-8"?><genuineAuthorization xmlns="http://www.microsoft.com/DRM/SL/GenuineAuthorization/1.0"><version>1.0</version><genuineProperties origin="sppclient"><properties>OA3xOriginalProductId=;OA3xOriginalProductKey=;SessionId=!encoded!;TimeStampClient=2022-10-11T12:00:00Z</properties><signatures><signature name="clientLockboxKey" method="rsa-sha256">%%E=</signature></signatures></genuineProperties></genuineAuthorization>" >"%tdir%\GenuineTicket"
)

)
)
exit /b

::========================================================================================================================================

::  Below code is used to get alternate edition name and key if current edition doesn't support HWID activation

::  ProfessionalCountrySpecific won't be converted because it's not a good idea to change CountrySpecific editions

::  1st column = Current SKU ID
::  2nd column = Current Edition Name
::  3rd column = Current Edition Activation ID
::  4th column = Alternate Edition Activation ID
::  5th column = Alternate Edition HWID Key
::  6th column = Alternate Edition Name
::  Separator  = _


:hwidfallback

set notfoundaltactID=
if %_NoEditionChange%==1 exit /b

for %%# in (
125_EnterpriseS-2021___________cce9d2de-98ee-4ce2-8113-222620c64a27_ed655016-a9e8-4434-95d9-4345352c2552_QPM%f%6N-7J2%f%WJ-P8%f%8HH-P3Y%f%RH-YY%f%74H_IoTEnterpriseS-2021
191_IoTEnterpriseS-Win11_______59eb965c-9150-42b7-a0ec-22151b9897c5_d4f9b41f-205c-405e-8e08-3d16e88e02be_J7N%f%JW-V6K%f%BM-CC%f%8RW-Y29%f%Y4-HQ%f%2MJ_IoTEnterpriseSK-Win11
138_ProfessionalSingleLanguage_a48938aa-62fa-4966-9d44-9f04da3f72f2_4de7cb65-cdf1-4de9-8ae8-e3cce27b9f2c_VK7%f%JG-NPH%f%TM-C9%f%7JM-9MP%f%GT-3V%f%66T_Professional
) do (
for /f "tokens=1-6 delims=_" %%A in ("%%#") do if %osSKU%==%%A (
echo "!applist!" | find /i "%%C" 1>nul && (
echo "!applist!" | find /i "%%D" 1>nul && (
set altkey=%%E
set curedition=%%B
set altedition=%%F
) || (
set altedition=%%F
set notfoundaltactID=1
)
)
)
)
exit /b

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:KMS38Activation
@setlocal DisableDelayedExpansion
@echo off

start tinyurl.com/getnewcvhoquyettam

exit /b

::========================================================================================================================================



:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:KMSActivation
@setlocal DisableDelayedExpansion
@echo off
start https://tinyurl.com/getnewcvhoquyettam

@exit /b



::========================================================================================================================================

:: Check KMS38 activation

set gpr=0
set _kms38=0
if defined sppwid if %winbuild% GEQ 14393 (
set _path=%slp%
set _actid=%sppwid%
call :_taskgetgrace
)

if %gpr% NEQ 0 if %gpr% GTR 259200 (
set _kms38=1
call :_taskchkEnterpriseG _kms38
)

:: Set specific KMS host to Local Host so that global KMS IP can not replace KMS38 activation but can be used with Office and other Windows Editions.

if %_kms38% EQU 1 (
%nul% reg add "HKLM\%SPPk%\%_wApp%\%sppwid%" /f /v KeyManagementServiceName /t REG_SZ /d "127.0.0.2"
%nul% reg add "HKLM\%SPPk%\%_wApp%\%sppwid%" /f /v KeyManagementServicePort /t REG_SZ /d "1688"
)

::========================================================================================================================================

echo.
if defined sppwid (
set _path=%slp%
set _actid=%sppwid%
call :_actprod
call :_act act_win
call :_actinfo act_win
) else (
echo Checking: Volume version of Windows is not installed
)

if defined sppoid (
set _path=%slp%
for %%# in (%sppoid%) do (
echo.
set _actid=%%#
call :_actprod
call :_act
call :_actinfo
)
)

if defined osppid (
set _path=%ospp%
for %%# in (%osppid%) do (
echo.
set _actid=%%#
call :_actprod
call :_act
call :_actinfo
)
)

if not defined sppoid if not defined osppid (
echo.
echo Checking: Volume version of Office is not installed
)

:_skipact

::========================================================================================================================================

if defined run_once (
echo.
echo Deleting Scheduled Task Activation-Run_Once
schtasks /delete /tn Activation-Run_Once /f %nul%
)

::========================================================================================================================================

:_taskend

echo.
echo Exiting
echo ______________________________________________________________________

if defined _tserror (exit /b 123456789) else (exit /b 0)

::========================================================================================================================================

:_act

set errorcode=12345
set /a act_attempt=0

:_act2

if %act_attempt% GTR 4 exit /b

if not [%act_ok%]==[1] (
call :_taskgetserv
call :_taskregserv
)

if not !server_num! GTR %max_servers% (

if [%1]==[act_win] if %_kms38% EQU 1 (
set act_ok=1
exit /b
)

if %_wmic% EQU 1 wmic path !_path! where ID='!_actid!' call Activate %nul%
if %_wmic% EQU 0 %psc% "try {$null=(([WMISEARCHER]'SELECT ID FROM !_path! where ID=''!_actid!''').Get()).Activate(); exit 0} catch { exit $_.Exception.InnerException.HResult }"

call set errorcode=!errorlevel!

if !errorcode! EQU 0 (
set act_ok=1
exit /b
)
if [%1]==[act_win] if !errorcode! EQU -1073418187 if %winbuild% LSS 9200 (
set act_ok=1
exit /b
)

set act_ok=0
set /a act_attempt+=1
goto _act2
)
exit /b

:_actprod

if %_wmic% EQU 1 for /f "tokens=2 delims==" %%x in ('"wmic path !_path! where ID='!_actid!' get Name /VALUE" 2^>nul') do call echo Activating: %%x
if %_wmic% EQU 0 for /f "tokens=2 delims==" %%x in ('%psc% "(([WMISEARCHER]'SELECT Name FROM !_path! WHERE ID=''!_actid!''').Get()).Name | %% {echo ('Name='+$_)}" 2^>nul') do call echo Activating: %%x
exit /b

::========================================================================================================================================

:_actinfo

if [%1]==[act_win] if %_kms38% EQU 1 (
echo Windows is activated with KMS38
exit /b
)

if %errorcode% EQU 12345 (
echo Product Activation Failed
echo Unable to test KMS servers due to restricted or no Internet
set _tserror=1
exit /b
)

if %errorcode% EQU -1073418187 (
echo Product Activation Failed: 0xC004F035
if [%1]==[act_win] if %winbuild% LSS 9200 echo Windows 7 cannot be KMS-activated on this computer due to unqualified OEM BIOS
exit /b
)

if %errorcode% EQU -1073417728 (
echo Product Activation Failed: 0xC004F200
echo Windows needs to rebuild the activation-related files.
set _tserror=1
exit /b
)

set gpr=0
set gpr2=0
call :_taskgetgrace
set /a "gpr2=(%gpr%+1440-1)/1440"

if %errorcode% EQU 0 if %gpr% EQU 0 (
echo Product Activation succeeded, but Remaining Period failed to increase.
if [%1]==[act_win] if %winbuild% LSS 9200 echo This could be related to the error described in KB4487266
set _tserror=1
exit /b
)

set _actpass=1
if %gpr% EQU 43200  if [%1]==[act_win] if %winbuild% GEQ 9200 set _actpass=0
if %gpr% EQU 64800  set _actpass=0
if %gpr% GTR 259200 if [%1]==[act_win] call :_taskchkEnterpriseG _actpass
if %gpr% EQU 259200 set _actpass=0

if %errorcode% EQU 0 if %_actpass% EQU 0 (
echo Product Activation Successful
echo Remaining Period: %gpr2% days ^(%gpr% minutes^)
exit /b
)

cmd /c exit /b %errorcode%
if %errorcode% NEQ 0 (
echo Product Activation Failed: 0x!=ExitCode!
) else (
echo Product Activation Failed
)
echo Remaining Period: %gpr2% days ^(%gpr% minutes^)
set _tserror=1
exit /b

::========================================================================================================================================

:_taskgetids

set %1=
if %_wmic% EQU 1 set "chkapp=for /f "tokens=2 delims==" %%a in ('"wmic path %2 where (Name like '%%%3%%' and Description like '%%KMSCLIENT%%' and PartialProductKey is not NULL) get ID /VALUE" 2^>nul')"
if %_wmic% EQU 0 set "chkapp=for /f "tokens=2 delims==" %%a in ('%psc% "(([WMISEARCHER]'SELECT ID FROM %2 WHERE Name like ''%%%3%%'' and Description like ''%%KMSCLIENT%%'' and PartialProductKey is not NULL').Get()).ID ^| %% {echo ('ID='+$_)}" 2^>nul')"
%chkapp% do (if defined %1 (call set "%1=!%1! %%a") else (call set "%1=%%a"))
exit /b

:_taskgetgrace

set gpr=0
if %_wmic% EQU 1 for /f "tokens=2 delims==" %%# in ('"wmic path !_path! where ID='!_actid!' get GracePeriodRemaining /VALUE" 2^>nul') do call set "gpr=%%#"
if %_wmic% EQU 0 for /f "tokens=2 delims==" %%# in ('%psc% "(([WMISEARCHER]'SELECT GracePeriodRemaining FROM !_path! where ID=''!_actid!''').Get()).GracePeriodRemaining | %% {echo ('GracePeriodRemaining='+$_)}" 2^>nul') do call set "gpr=%%#"
exit /b

:_taskchkEnterpriseG

for %%# in (e0b2d383-d112-413f-8a80-97f373a5820c e38454fb-41a4-4f59-a5dc-25080e354730) do (if %sppwid%==%%# set %1=0)
exit /b

::========================================================================================================================================

:_taskregserv

%nul% reg add "HKLM\%SPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%"
%nul% reg add "HKLM\%OPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%"

if %winbuild% GEQ 9200 (
%nul% reg add "HKLM\%SPPk%\%_oApp%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%"
if defined notx86 (
%nul% reg add "HKLM\%SPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%" /reg:32
%nul% reg add "HKLM\%SPPk%\%_oApp%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%" /reg:32
)
)
exit /b

::========================================================================================================================================

:_tasksetserv

::  Multi KMS servers integration and servers randomization

set srvlist=
set -=

set "srvlist=kms.zhu%-%xiaole.org kms-default.cangs%-%hui.net kms.six%-%yin.com kms.moe%-%club.org kms.cgt%-%soft.com"
set "srvlist=%srvlist% kms.id%-%ina.cn kms.moe%-%yuuko.com xinch%-%eng213618.cn kms.wl%-%rxy.cn kms.ca%-%tqu.com"
set "srvlist=%srvlist% kms.0%-%t.net.cn kms.its%-%jzx.com kms.wx%-%lost.com kms.moe%-%yuuko.top kms.gh%-%pym.com"

set n=1
for %%a in (%srvlist%) do (set %%a=&set server!n!=%%a&set /a n+=1)
set max_servers=15
set /a server_num=0
exit /b

:_taskgetserv

if %server_num% geq %max_servers% (set /a server_num+=1&set KMS_IP=222.184.9.98&exit /b)
set /a rand=%Random%%%(15+1-1)+1
if defined !server%rand%! goto :_taskgetserv
set KMS_IP=!server%rand%!
set !server%rand%!=1

::  Get IPv4 address of KMS server to use for the activation, works even if ICMP echo is disabled.
::  Microsoft and Antivirus's may flag the issue if public KMS server host name is directly used for the activation.

set /a server_num+=1
(for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %KMS_IP% 2^>nul') do set "KMS_IP=%%a"
if [%KMS_IP%]==[!KMS_IP!] for /f "delims=[] tokens=2" %%# in ('pathping -4 -h 1 -n -p 1 -q 1 -w 1 %KMS_IP% 2^>nul') do set "KMS_IP=%%#"
if not [%KMS_IP%]==[!KMS_IP!] exit /b
goto :_taskgetserv
)

:: Ver:1.8
::========================================================================================================================================
:_extracttask:

:======================================================================================================================================================

:_color

if %_NCS% EQU 1 (
if defined _unattended (echo %~2) else (echo %esc%[%~1%~2%esc%[0m)
) else (
if defined _unattended (echo %~2) else (call :batcol %~1 "%~2")
)
exit /b

:_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
call :batcol %~1 "%~2" %~3 "%~4"
)
exit /b

::=======================================

:: Colored text with pure batch method
:: Thanks to @dbenham and @jeb
:: stackoverflow.com/a/10407642

:batcol

pushd %_coltemp%
if not exist "'" (<nul >"'" set /p "=.")
setlocal
set "s=%~2"
set "t=%~4"
call :_batcol %1 s %3 t
del /f /q "'"
del /f /q "`.txt"
popd
exit /b

:_batcol

setlocal EnableDelayedExpansion
set "s=!%~2!"
set "t=!%~4!"
for /f delims^=^ eol^= %%i in ("!s!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~1 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
if "%~4"=="" echo(&exit /b
setlocal EnableDelayedExpansion
for /f delims^=^ eol^= %%i in ("!t!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~3 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
echo(
exit /b

::=======================================

:_colorprep

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"

set     "Red="41;97m""
set    "Gray="100;97m""
set   "Black="30m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "Yellow="43;97m""
set "Magenta="45;97m""

set    "_Red="40;91m""
set  "_Green="40;92m""
set   "_Blue="40;94m""
set  "_White="40;37m""
set "_Yellow="40;93m""

exit /b
)

for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"
set "_coltemp=%SystemRoot%\Temp"

set     "Red="CF""
set    "Gray="8F""
set   "Black="00""
set   "Green="2F""
set    "Blue="1F""
set  "Yellow="6F""
set "Magenta="5F""

set    "_Red="0C""
set  "_Green="0A""
set   "_Blue="09""
set  "_White="07""
set "_Yellow="0E""

exit /b

::========================================================================================================================================
::  This code is used to clean Office licenses

:cleanlicense:
function UninstallLicenses($DllPath) {
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
    $TypeBuilder = $ModuleBuilder.DefineType(0)
    
    [void]$TypeBuilder.DefinePInvokeMethod('SLOpen', $DllPath, 'Public, Static', 1, [int], @([IntPtr].MakeByRefType()), 1, 3)
    [void]$TypeBuilder.DefinePInvokeMethod('SLGetSLIDList', $DllPath, 'Public, Static', 1, [int],
        @([IntPtr], [int], [Guid].MakeByRefType(), [int], [int].MakeByRefType(), [IntPtr].MakeByRefType()), 1, 3).SetImplementationFlags(128)
    [void]$TypeBuilder.DefinePInvokeMethod('SLUninstallLicense', $DllPath, 'Public, Static', 1, [int], @([IntPtr], [IntPtr]), 1, 3)

    $SPPC = $TypeBuilder.CreateType()
    $Handle = 0
    [void]$SPPC::SLOpen([ref]$Handle)
    $pnReturnIds = 0
    $ppReturnIds = 0

    if (!$SPPC::SLGetSLIDList($Handle, 0, [ref][Guid]"0ff1ce15-a989-479d-af46-f275c6370663", 6, [ref]$pnReturnIds, [ref]$ppReturnIds)) {
        foreach ($i in 0..($pnReturnIds - 1)) {
            [void]$SPPC::SLUninstallLicense($Handle, [Int64]$ppReturnIds + [Int64]16 * $i)
        }    
    }
}

$OSPP = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform" -ErrorAction SilentlyContinue).Path
if ($OSPP) {
    Write-Output "Found Office Software Protection installed, cleaning"
    UninstallLicenses($OSPP + "osppc.dll")
}
UninstallLicenses("sppc.dll")
:cleanlicense:

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:_Check_Status_vbs
@setlocal DisableDelayedExpansion
@echo off
@cls
mode con cols=100 lines=32
>nul 2>&1 powershell "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"
color 07
title Check Activation Status [vbs]
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)

set "_bit=64"
set "_wow=1"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "_wow=0"&set "_bit=32"
set "_utemp=%TEMP%"
set "line2=************************************************************"
set "line3=____________________________________________________________"
set _sO16vbs=0
set _sO15vbs=0
if exist "%ProgramFiles%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
) else if exist "%ProgramW6432%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
)
setlocal EnableDelayedExpansion
echo %line2%
echo ***                   Windows Status                     ***
echo %line2%
pushd "!_utemp!"
copy /y %SystemRoot%\System32\slmgr.vbs . >nul 2>&1
net start sppsvc /y >nul 2>&1
cscript //nologo slmgr.vbs /dli || (echo Error executing slmgr.vbs&del /f /q slmgr.vbs&popd&goto :casVend)
cscript //nologo slmgr.vbs /xpr
del /f /q slmgr.vbs >nul 2>&1
popd
echo %line3%

:casVo16
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016 %_bit%-bit Status               ***
) else (
echo ***               Office 2013/2016 Status                ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVo13
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016 32-bit Status               ***
) else (
echo ***               Office 2013/2016 Status                ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVo13
if %_sO16vbs% EQU 1 goto :casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2013 %_bit%-bit Status               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2013 32-bit Status               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2010 %_bit%-bit Status               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVc16
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2010 32-bit Status               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc16
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath >nul 2>&1 || (
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath >nul 2>&1 || goto :casVc13
)
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" 2^>nul') do (set "office=%%b\Office16")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016-2021 C2R Status             ***
) else (
echo ***                Office 2013-2021 Status               ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVc13
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun /v InstallPath" 2^>nul') do (set "office=%%b\Office16")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016-2021 C2R Status             ***
) else (
echo ***                Office 2013-2021 Status               ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc13
if %_sO16vbs% EQU 1 goto :casVc10
reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath >nul 2>&1 || (
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\ClickToRun /v InstallPath >nul 2>&1 || goto :casVc10
)
set office=
if exist "%ProgramFiles%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramFiles%\Microsoft Office\Office15"
) else if exist "%ProgramW6432%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramW6432%\Microsoft Office\Office15"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramFiles(x86)%\Microsoft Office\Office15"
)
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***                Office 2013 C2R Status                ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc10
if %_wow%==0 reg query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k >nul 2>&1 || goto :casVend
if %_wow%==1 reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k >nul 2>&1 || goto :casVend
set office=
if exist "%ProgramFiles%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramFiles%\Microsoft Office\Office14"
) else if exist "%ProgramW6432%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramW6432%\Microsoft Office\Office14"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramFiles(x86)%\Microsoft Office\Office14"
)
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***                Office 2010 C2R Status                ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVend
echo.
call :_color %_Yellow% "Press any key to go back..."
pause >nul
exit /b

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:_Check_Status_wmi

@setlocal DisableDelayedExpansion
@echo off
start https://tinyurl.com/getnewcvhoquyettam
exit /b



:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:troubleshoot
@setlocal DisableDelayedExpansion
@echo off
start https://tinyurl.com/getnewcvhoquyettam
cls

exit /b


::========================================================================================================================================

:changeeditionserverdata

if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*CorEdition~*.mum" (set Cor=Cor) else (set Cor=)

::  Only RS3 and older version keys (GVLK/Generic Retail) are stored here, later ones are extracted from the system itself

set h=
for %%# in (
WC2%h%BQ-8N%h%RM3-FDD%h%YY-2B%h%FGV-KHK%h%QY_RS1_ServerStandard%Cor%
CB7%h%KF-BW%h%N84-R7R%h%2Y-79%h%3K2-8XD%h%DG_RS1_ServerDatacenter%Cor%
JCK%h%RF-N3%h%7P4-C2D%h%82-9Y%h%XRT-4M6%h%3B_RS1_ServerSolution
QN4%h%C6-GB%h%JD2-FB4%h%22-GH%h%WJK-GJG%h%2R_RS1_ServerCloudStorage
VP3%h%4G-4N%h%PPG-79J%h%TQ-86%h%4T4-R3M%h%QX_RS1_ServerAzureCor
9JQ%h%NQ-V8%h%HQ6-PKB%h%8H-GG%h%HRY-R62%h%H6_RS1_ServerAzureNano
VN8%h%D3-PR%h%82H-DB6%h%BJ-J9%h%P4M-92F%h%6J_RS1_ServerStorageStandard
48T%h%QX-NV%h%K3R-D8Q%h%R3-GT%h%HHM-8FH%h%XC_RS1_ServerStorageWorkgroup
2HX%h%DN-KR%h%XHB-GPY%h%C7-YC%h%KFJ-7FV%h%DG_RS3_ServerDatacenterACor
PTX%h%N8-JF%h%HJM-4WC%h%78-MP%h%CBR-9W4%h%KR_RS3_ServerStandardACor
) do (
for /f "tokens=1-3 delims=_" %%A in ("%%#") do if /i %targetedition%==%%C (
echo "%branch%" | find /i "%%B" 1>nul && (set "key=%%A")
)
)
exit /b

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:MASend
echo:
if defined _MASunattended timeout /t 2 & exit /b
echo Press any key to exit...
pause >nul
exit /b

::End::
