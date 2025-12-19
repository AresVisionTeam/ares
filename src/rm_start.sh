#!/bin/bash

# 检查间隔时间，每隔sec秒查看一次当前线程是否正常运行
sec=7
# 异常统计数，超过5次重新make，超过20次reboot
remakecnt=0
rebootcnt=0
#进程名字，取决于CMake的项目名称，即可执行文件的名称，也可以在启动程序后在终端输入top/ps来查找
PROC_NAME=armor_solver_node
CODE_PATH=/home/core/ares


# 进入文件里面
cd ${CODE_PATH}

# 新建一个terminal在里面运行程序，方便监视程序的情况,若要ssh链接则直接运行，替换为./YueLuRMVision2022
gnome-terminal -- bash -c "source /opt/ros/humble/setup.bash;source ./install/setup.bash;ros2 launch rm_bringup bringup.launch.py;exec bash"
echo "[daemon]: ${PROC_NAME} has started!"

sleep ${sec} 

while [ 1 ] # 中括号的判断条件两边要空格
do
# 判定进程运行否，是则继续，否则重新启动
# ps列出进程，-ef给出进程的详细信息，grep捕获我们的进程，
# grep -v把grep进程去掉，否则grep也会把自己统计进来，wc(word count) -l(line)统计进程数
# 当程序正常运行的时候，tcount>=1(多线程）
tcount=`ps -ef | grep ${PROC_NAME} | grep -v "grep" | wc -l` 
echo "[daemon]:Thread count: ${tcount}"
if [ ${tcount} -ge 1 ];then  # -ge greater equal，大于等于1情况下 进程没被杀害
	echo "[daemon]: ${PROC_NAME} is running..."
	sleep ${sec} 
else  # 出现异常，进程未运行
	# 异常统计数累加
	rebootcnt=`expr ${rebootcnt} + 1`
	remakecnt=`expr ${remakecnt} + 1`
	
	if [ ${rebootcnt} -gt 20 ];then # 大于20，直接重开！
		echo " " | sudo -S reboot
	fi
	
	# 小于五次，尝试重新运行程序
	echo -e "\033[31m[daemon]:${PROC_NAME} error! \033[0m" 
	echo -e "\033[31m[daemon]:Trying to restart ${PROC_NAME}...\033[0m" 
	echo -e "\033[32m[daemon]:retry counts: ${rebootcnt} \033[0m"
	cd ${CODE_PATH}
   	gnome-terminal -- bash -c "source /opt/ros/humble/setup.bash;source ./install/setup.bash;ros2 launch rm_bringup bringup.launch.py;exec bash"
	echo -e "\033[34m [daemon]:${PROC_NAME} restart successfully! \033[0m"
	sleep ${sec}
	
fi  
done


