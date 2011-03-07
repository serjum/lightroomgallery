<?php
    defined('_JEXEC') or die('Restricted Access');
?>

<tr>
    <th width="5%">
        <input type="checkbox" name="toggle" value="" onclick="checkAll(<?php echo count($this->items); ?>);" />
    </th>
    <th width="20%">
        Фотография
    </th>
    <th width="20%">
        Поле метаданных
    </th>
    <th width="25%">
        Значение
    </th>
    <th width="30%">
        Описание
    </th>
</tr>