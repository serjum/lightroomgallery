<?php
    defined('_JEXEC') or die('Restricted Access');
?>

<tr>
    <th width="5%">
        <input type="checkbox" name="toggle" value="" onclick="checkAll(<?php echo count($this->items); ?>);" />
    </th>
    <th width="35%">
        Поле метаданных
    </th>
    <th width="55%">
        Описание
    </th>
    <th width="5%">
        Id
    </th>
</tr>