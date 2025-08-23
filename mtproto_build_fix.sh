#!/bin/bash

# MTProto Proxy Build Fix Script
# این اسکریپت مشکل multiple definition را حل می‌کند

set -e  # در صورت خطا متوقف شود

echo "🔧 شروع حل مشکل MTProto Proxy Build..."

# رنگ‌ها برای خروجی بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# تابع برای نمایش پیام‌های رنگی
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# چک کردن وجود Makefile
if [ ! -f "Makefile" ]; then
    print_error "Makefile یافت نشد! لطفاً در پوشه پروژه اجرا کنید."
    exit 1
fi

print_status "چک کردن نسخه GCC..."
gcc_version=$(gcc --version | head -n1)
echo "نسخه GCC: $gcc_version"

# پاک کردن فایل‌های object قبلی
print_status "پاک کردن فایل‌های object قبلی..."
if make clean > /dev/null 2>&1; then
    print_success "فایل‌های object پاک شدند"
else
    print_warning "make clean با خطا مواجه شد، ادامه می‌دهیم..."
fi

# روش 1: استفاده از فلگ -fcommon
print_status "تلاش برای build با فلگ -fcommon..."
export CFLAGS="-fcommon"

if make CFLAGS="-fcommon" > build.log 2>&1; then
    print_success "✅ Build با موفقیت انجام شد!"
    print_success "فایل executable در مسیر: objs/bin/mtproto-proxy"
    
    # چک کردن وجود فایل نهایی
    if [ -f "objs/bin/mtproto-proxy" ]; then
        ls -la objs/bin/mtproto-proxy
        print_success "🎉 همه چیز آماده است!"
    fi
    exit 0
fi

print_warning "روش اول شکست خورد، تلاش برای روش دوم..."

# روش 2: تغییر Makefile
print_status "بک‌آپ گرفتن از Makefile..."
cp Makefile Makefile.backup

print_status "اضافه کردن -fcommon به Makefile..."

# اضافه کردن -fcommon به CFLAGS در Makefile
if grep -q "CFLAGS.*-fcommon" Makefile; then
    print_warning "-fcommon قبلاً در Makefile موجود است"
else
    # پیدا کردن خط CFLAGS و اضافه کردن -fcommon
    if grep -q "^CFLAGS" Makefile; then
        sed -i 's/^CFLAGS *= */CFLAGS = -fcommon /' Makefile
    else
        # اگر CFLAGS وجود نداشت، اضافه کردن آن
        echo "CFLAGS = -fcommon" >> Makefile
    fi
    print_success "-fcommon به Makefile اضافه شد"
fi

# تلاش مجدد برای build
print_status "تلاش مجدد برای build..."
if make > build.log 2>&1; then
    print_success "✅ Build با موفقیت انجام شد!"
    print_success "فایل executable در مسیر: objs/bin/mtproto-proxy"
    
    if [ -f "objs/bin/mtproto-proxy" ]; then
        ls -la objs/bin/mtproto-proxy
        print_success "🎉 همه چیز آماده است!"
    fi
    exit 0
fi

print_warning "روش دوم نیز شکست خورد، تلاش برای روش سوم..."

# روش 3: استفاده از فلگ‌های اضافی
print_status "تلاش با فلگ‌های اضافی..."

# بازگرداندن Makefile اصلی
cp Makefile.backup Makefile

export CFLAGS="-fcommon -Wno-error"
export LDFLAGS="-Wl,--allow-multiple-definition"

if make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" > build.log 2>&1; then
    print_success "✅ Build با موفقیت انجام شد!"
    print_success "فایل executable در مسیر: objs/bin/mtproto-proxy"
    
    if [ -f "objs/bin/mtproto-proxy" ]; then
        ls -la objs/bin/mtproto-proxy
        print_success "🎉 همه چیز آماده است!"
    fi
    exit 0
fi

# اگر همه روش‌ها شکست خوردند
print_error "❌ همه روش‌ها شکست خوردند!"
print_error "لاگ خطاها:"
echo "----------------------------------------"
cat build.log
echo "----------------------------------------"

print_warning "پیشنهادات:"
echo "1. کد منبع را از مخزن اصلی دوباره clone کنید"
echo "2. نسخه قدیمی‌تری از GCC نصب کنید"
echo "3. با نگهدارنده پروژه تماس بگیرید"

# بازگرداندن Makefile اصلی
if [ -f "Makefile.backup" ]; then
    cp Makefile.backup Makefile
    rm Makefile.backup
    print_status "Makefile به حالت اصلی بازگردانده شد"
fi

exit 1