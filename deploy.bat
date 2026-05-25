@echo off
echo ===================================================
echo 🌿 Nucis & Co. - One-Click Production Deployment 🌿
echo ===================================================
echo.

echo 📦 Step 1: Compiling React/Vite Storefront...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Build failed! Deployment aborted.
    pause
    exit /b %errorlevel%
)

echo.
echo 📦 Step 2: Compressing build directory...
tar -czf nucis_dist.tar.gz dist
if %errorlevel% neq 0 (
    echo ❌ Compression failed!
    pause
    exit /b %errorlevel%
)

echo.
echo 🚀 Step 3: SCP uploading to AWS EC2 (13.207.1.144)...
scp -i C:\Users\Shariff\.ssh\business_prod_key.pem nucis_dist.tar.gz ubuntu@13.207.1.144:/home/ubuntu/nucis_dist.tar.gz
if %errorlevel% neq 0 (
    echo ❌ Upload failed! Please check your SSH connection.
    del nucis_dist.tar.gz
    pause
    exit /b %errorlevel%
)

echo.
echo 🔧 Step 4: Extracting storefront assets in /var/www/nucis/...
ssh -i C:\Users\Shariff\.ssh\business_prod_key.pem ubuntu@13.207.1.144 "sudo rm -rf /var/www/nucis/* && tar -xzf /home/ubuntu/nucis_dist.tar.gz -C /var/www/nucis/ --strip-components=1 && rm /home/ubuntu/nucis_dist.tar.gz"
if %errorlevel% neq 0 (
    echo ❌ Remote extraction failed!
    del nucis_dist.tar.gz
    pause
    exit /b %errorlevel%
)

echo.
echo 🧹 Step 5: Cleaning up local temporary archives...
del nucis_dist.tar.gz

echo.
echo ===================================================
echo 🎉 SUCCESS! Storefront is live on http://13.207.1.144 🎉
echo ===================================================
pause
