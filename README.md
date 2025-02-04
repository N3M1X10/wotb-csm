![](https://repository-images.githubusercontent.com/470124242/8a45d49c-74da-4a70-a190-03046d1691ea)

> [!caution]
> ### Рекомендуется прочитать инструкции ниже!

## Краткое описание программы
- **`Tanks Blitz - CIS - Cluster Settings Menu`** - Меню настройки кластеров СНГ сервера игры Tanks Blitz.
- В программе вы можете в пару кликов создать правила в брандмауэр, которые заблокируют исходящее подключение к серверу игры.
- А после открыть подключение только к определённому, нужному вам, кластеру сервера игры.
- Таким образом можно принудительно выбрать кластер - на котором вы будете играть.

<details>
  <summary>Окно программы</summary>
  
  ![image](https://github.com/user-attachments/assets/4a5f7d8e-d837-4aee-9114-b75a4535e19a)

</details>


## Перед обновленем `wotb-csm`
>[!important]
> ### Перед обновлением на новую версию `wotb-csm` делаем следующее:
> 1. **`del`** - удалить правила блокирования клаcтеров
> 2. Качаем актуальную сборку `wotb-csm`
> 3.  **`create`** - создаём правила снова
> - Это делается для того чтобы корректно обновить ip-адреса кластеров в брандмауэре - на актуальные. В противном случае - блокировка не будет работать.
> - В случае неполадок вы можете вручную удалить правила блокирования кластеров в Брандмауэре Windows.
>   * Команда **`wf`** - откроет его


## Первым делом
1) Запускаем **`wotb-csm.bat`**
2) Перед началом работы обязательно пропишите команду **`create`**. И подтвердите действие буквой `Y`
>[!important]
> - Эта команда необходима для блокировки кластеров.
> - Она создаёт правила в брандмауэре Windows и автоматически блокирует все кластера.

> [!caution]
> **Это значит что вы не сможете зайти в игру и подключиться к серверу !!!**
> - Читайте далее, чтобы настроить кластера правильно.


# Настройка кластеров
> [!warning]
> Для того чтобы выбрать кластер, введите соответствующую команду для разблокировки нужного вам кластера

### Пример:
- **`ub0`** - чтобы разблокировать кластер **RU_C0**, тогда на него можно будет зайти.
- А если надоел **RU_C0** то блокируем его: **`b0`**

> [!tip]
> ### Также, если вы не уверены в том, какие кластера заблокированы, а какие нет:
> 1. **`b`** / **`block`** - заблокируйте все
> 2. **`ub<номер кластера>`** - разблокируйте тот, на котором хотите играть.

>[!note]
> Вы можете выбрать столько кластеров - сколько захотите. Важно только вводить команды отдельно, одну команду - на один кластер.

> [!tip]
> - Если потребуется разблокировать все кластера без удаления правил, введите команду: **`ub`** / **`unblock`**.
> - На случай если нужно удалить правила из брандмауэра(обычно после обновления), команда: **`del`** / **`delete`**
> - Это удалит все созданные этим пакетом, правила в брандмауэре.


# Примечания

  ### Почему игра не подключается к серверу?
  
  - Если после долгих попыток подключиться, игра не пускает на сервер - убедитесь что блокируются не все кластера, команда: **`wf`** откроет Windows Firewall, -> Исходящие правила
  > [!warning]
  > Если все правила имеют красный значок - вы не сможете играть
  > 
  > ![image](https://github.com/user-attachments/assets/08f0d0ed-2f8e-44a6-b6d1-d8390ca042ab)
  
  - Также можно проверить доступность кластера(-ов) через **`cluster-checker.bat`**, [читайте о нём здесь](https://github.com/N3M1X10/wotb-csm/blob/master/cluster-checker-guide.md)


### Долгое переключение с кластера на кластер

Иногда, после блокировки кластеров и выбора нужного(-ых) вам - игра сразу не даёт войти на кластер(-а), который(-е) вы выбрали.

Такое происходит из-за того - что игра до последнего стучится на тот кластер, который считает оптимальным выбором на данный момент.

Если вы убедились что кластер, на который вы хотите подключиться - активен / подключение не блокируется по другой причине: то спустя несколько попыток переподключения - игра всё равно переключит вас на выбранный вами кластер.  



## Обратная связь
- Не работает wotb-csm? Создайте тему в **[Issues](https://github.com/N3M1X10/wotb-csm/issues)**!
- Либо свяжитесь с владельцем [Discord](https://discord.gg/2jJ3Qn4) сервера

## Поддержка
При желании, если хотите поддержать автора - [Boosty](https://boosty.to/nemix/donate)
