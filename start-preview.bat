@echo off
chcp 65001 >nul
echo ==========================================
echo  Pleasant233 Blog - Local Preview
echo ==========================================
echo.
cd /d D:\Pleasantweb\Pleasant233.github.io
echo Starting Hexo server...
echo.
echo Access your blog at: http://localhost:4000
echo Daily briefing at: http://localhost:4000/2026/03/02/daily-briefing-2026-03-02/
echo.
echo Press Ctrl+C to stop
echo ==========================================
node_modules\.bin\hexo.cmd server
pause