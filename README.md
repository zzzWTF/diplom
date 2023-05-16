
#  Дипломная работа по профессии «Системный администратор»


## Инфраструктура
Для развёртки инфраструктуры использовались Terraform и Ansible. Hosts inventory.ini для Ansible создается автоматически из шаблона terraform.
![dashboard](/img/preview.png)
![Ansible ping](/img/ansible1.png)
![Ansible ping](/img/ansible2.png)

### Сайт
ВМ созданы согласно задания, сайт доступен по [адресу](http://158.160.102.50). ![Изображение](/img/computeCloud.png)
![Изображение](/img/l7b.png)
![Изображение](/img/l7b-map.png)

### Мониторинг
Созданы ВМ для Prometheus и [grafana](http://62.84.112.240:3000) (admin/admin), развернуты соответствующие сервисы. На каждую ВМ из веб-серверов установлены Node Exporter и Nginx Log Exporter. Prometheus настроен на сбор метрик с этих exporter. В grafana добавлен prometheus.


### Логи
Логи не настроены. ВМ созданы, развернуты docker-образы  bitnami/kibana и bitnami/elasticsearch.

### Сеть
Развернут один VPC.
![Изображение](/img/VPC.png) 
Сервера web, Prometheus, Elasticsearch в приватных подсетях. Сервера Grafana, Kibana, application load balancer, jump в публичной подсети.

Настроены Security groups.
![Изображение](/img/SG.png)

ВМ jump - бастионный хост, я использовал один ключ и одного пользователя для всех машин, поэтому к любой ВМ можно подключиться командой вида ssh -J admin@<внешний_ip_бастиона> admin@<внутренний_ip_ВМ>. Ansible настроен соответственно.

### Резервное копирование
Создано расписание snapshot дисков всех ВМ.
![Изображение](/img/backup.png)