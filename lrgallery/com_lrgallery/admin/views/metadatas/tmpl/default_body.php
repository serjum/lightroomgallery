<?php
    defined('_JEXEC') or die('Restricted Access');
?>

<?php foreach ($this->items as $i => $item): ?>
    <tr class="row<?php echo $i % 2; ?>">
        <td>
            <?php echo JHtml::_('grid.id', $i, $item->id); ?>
        </td>
        <td>
            <?php echo $item->photo_name; ?>
        </td>
        <td>
            <?php echo $item->meta_name; ?>
        </td>
        <td>
            <?php echo $item->value; ?>
        </td>
        <td>
            <?php echo $item->desc; ?>
        </td>
    </tr>
<?php endforeach; ?>