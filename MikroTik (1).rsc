# mar/01/2023 20:43:00 by RouterOS 7.7
# software id = KNLQ-5EZF
#
# model = RB2011iLS
# serial number = F6970F0EF5CD
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/port
set 0 name=serial0
/ip dhcp-client
add interface=ether2
/system clock
set time-zone-name=America/Guatemala
/system scheduler
add interval=5m name=Backup on-event="log info \"Iniciando respaldo\"\r\
    \n:global backupfile ([/system identity get name]. \".rsc\")\r\
    \n/export file=\$backupfile\r\
    \n:log info \"Creando el respaldo...\"\r\
    \n:delay 10s\r\
    \n:log info \"El respaldo esta siendo enviado a su correo\"\r\
    \n/tool e-mail send to=\"noc@loqui.com.gt\" subject=([/system identity get\
    \_name] . \\\r\
    \n\" Backup\") from=noc@loqui.com.gt file=\$backupfile\r\
    \n:log info \"Envio de respaldo finalizado\"\r\
    \n:delay 60\r\
    \n/file remove ([/system identity get name].\".rsc\")" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=mar/01/2023 start-time=20:43:00
/tool e-mail
set address=smtp.gmail.com from=noc@loqui.com.gt port=587 tls=starttls user=\
    noc@loqui.com.gt
