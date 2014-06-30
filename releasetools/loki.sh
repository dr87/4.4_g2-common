#!/sbin/sh
#
# This leverages the loki_patch utility created by djrbliss which allows us
# to bypass the bootloader checks on jfltevzw and jflteatt
# See here for more information on loki: https://github.com/djrbliss/loki
#

# 4.4 Kernel - Panel Detection - dr87
#
# Detect panel and swap cmdline as necessary 
# lcd_maker_id is determined by get_panel_maker_id on the hardware and is always accurate
# This searches directly in the boot.img before loki and has no other requirements
# Continue to build with either lgd or jdi cmdline
# Do not shorten the search or you may change the actual kernel source
#
#	LCD_RENESAS_LGD = 0,
#	LCD_RENESAS_JDI = 1

lcdmaker=$(grep -c "lcd_maker_id=1" /proc/cmdline)
if [ $lcdmaker == 1 ]; then
	echo "JDI panel detected"
	find boot.img -type f -exec sed -i 's/console=ttyHSL0,115200,n8 
androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 
mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd/console=ttyHSL0,115200,n8 
androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 
mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_jdi_cmd/g' {} \;
elif [ $lcdmaker == "0" ]; then
	echo "LGD panel detected"
	find boot.img -type f -exec sed -i 's/console=ttyHSL0,115200,n8 
androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 
mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_jdi_cmd/console=ttyHSL0,115200,n8 
androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 
mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd/g' {} \;
else
	echo "lcd_maker_id doesn't exist. Something went wrong."
fi

# Loki

export C=/tmp/loki_tmpdir

mkdir -p $C
dd if=/dev/block/platform/msm_sdcc.1/by-name/aboot of=$C/aboot.img
/system/bin/loki_patch boot $C/aboot.img /tmp/boot.img $C/boot.lok || exit 1
/system/bin/loki_flash boot $C/boot.lok || exit 1
rm -rf $C
exit 0
