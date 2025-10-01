# Создание объекта симулятора
set ns [new Simulator]

# Открытие файла трассировки
set tf [open out.tr w]
$ns trace-all $tf

# Определение параметров системы
set lambda 30.0
set mu 33.0
set qsize 100000
set duration 1000.0

# Создание узлов и соединения между ними
set n1 [$ns node]
set n2 [$ns node]

set link [$ns simplex-link $n1 $n2 100kb 0ms DropTail]
$ns queue-limit $n1 $n2 $qsize

# Настройка случайных переменных
set InterArrivalTime [new RandomVariable/Exponential]
$InterArrivalTime set avg_ [expr 1/$lambda]

set pktSize [new RandomVariable/Exponential]
$pktSize set avg_ [expr 100000.0/(8*$mu)]

# Создание агентов (источник и приемник)
set src [new Agent/UDP]
$src set packetSize_ 100000
$ns attach-agent $n1 $src

set sink [new Agent/Null]
$ns attach-agent $n2 $sink

$ns connect $src $sink

# Мониторинг очереди
set qmon [$ns monitor-queue $n1 $n2 [open qm.out w] 0.1]
$link queue-sample-timeout

# Функция завершения симуляции
proc finish {} {
    global ns tf
    $ns flush-trace
    close $tf
    exit 0
}

# Функция генерации пакетов
proc sendpacket {} {
    global ns src InterArrivalTime pktSize
    set time [$ns now]
    $ns at [expr $time + [$InterArrivalTime value]] "sendpacket"
    set bytes [expr round([$pktSize value])]
    $src send $bytes
}

# Запуск генерации пакетов и завершения симуляции
$ns at 0.0001 "sendpacket"
$ns at $duration "finish"

# Вычисление характеристик системы
set rho [expr $lambda/$mu]

set ploss [expr (1-$rho)*pow($rho,$qsize)/(1-pow($rho,($qsize+1)))]
puts "Теоретическая вероятность потери = $ploss"

set aveq [expr $rho*$rho/(1-$rho)]
puts "Теоретическая средняя длина очереди = $aveq"

# Запуск симуляции
$ns run

