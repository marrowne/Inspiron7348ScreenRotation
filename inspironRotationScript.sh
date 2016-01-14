#!/bin/bash

INTERVAL=2
ORIENTATION[0]=""
ORIENTATION[2]=""
PATH_TO_SENSORS="/sys/bus/iio/devices"
SENSOR_DIR=""

DEVICE[1]="ELAN Touchscreen"
DEVICE[2]="PS/2 Synaptics TouchPad"
DEVICE[3]="DLL0675:00 06CB:75DB UNKNOWN"
ROTATION_MATRIX[1]="1 0 0 0 1 0 0 0 1"
ROTATION_MATRIX[2]="0 1 0 -1 0 1 0 0 1"
ROTATION_MATRIX[3]="0 -1 1 1 0 0 0 0 1"
ROTATION_MATRIX[4]="-1 0 1 0 -1 1 0 0 1"
ROTATION_MATRIX[5]="-1 0 0 0 1 0 0 0 1"

for label in `find $PATH_TO_SENSORS/*/* -name "name"`
do
	if [ `cat $label` == "accel_3d" ]
	then
		SENSOR_DIR=`dirname $label`
	fi
done

function sensors {
	x_raw_file="in_accel_x_raw"
	y_raw_file="in_accel_y_raw"
	z_raw_file="in_accel_z_raw"
	scale_file="in_accel_scale"
	scale_val=`cat $1/$scale_file`

	x_raw_val=`cat $1/$x_raw_file`
	y_raw_val=`cat $1/$y_raw_file`
	z_raw_val=`cat $1/$z_raw_file`
	x=`echo "$x_raw_val * $scale_val"|bc`
	y=`echo "$y_raw_val * $scale_val"|bc`
	z=`echo "$z_raw_val * $scale_val"|bc`
#	echo $x $y $z

	x_lt=`echo "$x < -2.0"|bc`
	x_gt=`echo "$x > 2.0"|bc`
	y_lt=`echo "$y < -2.0"|bc`
	y_gt=`echo "$y > 2.0"|bc`
	z_lt=`echo "$z < -6.0"|bc`
	z_gt=`echo "$z > 5.0"|bc`

	if [ $z_gt == 1 ] || [ $z_lt == 1 ]
	then
			ORIENTATION[0]="flat"
	else
		if [ $x_lt == 0 ] && [ $x_gt == 0 ] && [ $y_lt == 0 ] && [ $y_gt == 0 ]
		then
			ORIENTATION[0]="normal"
		else
			if [ $x_lt == 0 ] && [ $x_gt == 0 ]
			then
				if [ $y_lt == 1 ]
				then
					ORIENTATION[0]="normal"
				else
					if [ $y_gt == 1 ]
					then
						ORIENTATION[0]="inverted"
					else
						ORIENTATION[0]="normal"
					fi
				fi
			else
				if [ $y_lt == 0 ] && [ $y_gt == 0 ]
				then
					if [ $x_lt == 1 ]
					then
						ORIENTATION[0]="right"
					else
						if [ $x_gt == 1 ]
						then
							ORIENTATION[0]="left"
						else
							ORIENTATION[0]="right"
						fi
					fi
				fi
			fi
		fi
	fi
}

function to_angle {
	case "$1" in
	"normal" )
		angle=0 ;;
	"left" )
		angle=90 ;;
	"inverted" )
		angle=180 ;;
	"right" )
		angle=270 ;;
	esac
}

function from_angle {
	case $1 in
	0 )
		angle="normal" ;;
	90 )
		angle="left" ;;
	180 )
		angle="inverted" ;;
	270 )
		angle="right" ;;
	esac
}
function screenRotation {
	if [ "$2" == "flat" ]
	then
		to_angle $1
		angle1=$angle
		to_angle $3
		angle2=$angle
	else
		to_angle $1
		angle1=$angle
		to_angle $2
		angle2=$angle
	fi

	rotation_angle=$(($angle1-$angle2))


	if [ $(($rotation_angle%180)) == 0 ]
	then
		# solution for KDE
		from_angle $(($(($angle2+90))%360))
		intermediate=$angle
		xrandr --screen 0 -o $intermediate && xrandr --screen 0 -o $1
	else
		xrandr --screen 0 -o $1
	fi

	if [ $1 == "normal" ]
	then
		for index in 1 3
		do
			xinput set-prop "${DEVICE[index]}" --type=float "Coordinate Transformation Matrix" ${ROTATION_MATRIX[1]}
		done
	fi

	if [ $1 == "right" ]
	then
		for index in 1 3
		do
			xinput set-prop "${DEVICE[index]}" --type=float "Coordinate Transformation Matrix" ${ROTATION_MATRIX[2]}
		done
	fi

	if [ $1 == "left" ]
	then
		for index in 1 3
		do
			xinput set-prop "${DEVICE[index]}" --type=float "Coordinate Transformation Matrix" ${ROTATION_MATRIX[3]}
		done
	fi

	if [ $1 == "inverted" ]
	then
		xinput set-prop "${DEVICE[1]}" --type=float "Coordinate Transformation Matrix" ${ROTATION_MATRIX[4]}
		for index in 2 3
		do
			xinput set-prop "${DEVICE[index]}" --type=float "Coordinate Transformation Matrix" ${ROTATION_MATRIX[5]}
		done
	fi
}

echo "
Dell Inspiron 7348's screen auto-rotation bash script ver. 1.0

Copyright (C) 2016 Michał Mordawski
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
"

sensors $SENSOR_DIR
ORIENTATION[1]=${ORIENTATION[0]}

while true
do
	sensors $SENSOR_DIR

	if [ "${ORIENTATION[0]}" != "${ORIENTATION[1]}" ]
	then
		if [ "${ORIENTATION[0]}" == "flat" ]
		then
			echo "screen locked"
		else
			if [ "${ORIENTATION[0]}" == "${ORIENTATION[2]}" ] && [ "${ORIENTATION[1]}" == "flat" ]
			then
				echo "screen unlocked"
			else
				screenRotation ${ORIENTATION[0]} ${ORIENTATION[1]} ${ORIENTATION[2]}
				echo "rotated ${ORIENTATION[0]}"
			fi
		fi
		ORIENTATION[2]=${ORIENTATION[1]}
		ORIENTATION[1]=${ORIENTATION[0]}
	fi

	sleep $INTERVAL
done
