<?php
    defined('_JEXEC') or die('Restricted Access');
?>

<tr>
    <th width="5%">
        <input type="checkbox" name="toggle" value="" onclick="checkAll(<?php echo count($this->items); ?>);" />
    </th>
    <th width="40%">
        Пользователь
    </th>
    <th width="50%">
        Имя файла
    </th>
    <th width="15%">
        Id
    </th>
</tr>