<?php
    defined('_JEXEC') or die('Restricted Access');
?>

<tr>
    <th width="5%">
        <input type="checkbox" name="toggle" value="" onclick="checkAll(<?php echo count($this->items); ?>);" />
    </th>
    <th width="45%">
        Пользователь
    </th>
    <th width="45%">
        Название папки
    </th>
    <th width="5%">
        Id
    </th>
</tr>