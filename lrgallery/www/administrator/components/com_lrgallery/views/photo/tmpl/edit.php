<?php
    defined('_JEXEC') or die('Restricted access');
    JHtml::_('behavior.tooltip');
?>

<form action="<? echo JRoute::_('index.php?option=com_lrgallery&layout=edit&id=' . (int) $this->item->id); ?>" method="post" name="adminForm" id="editPhotoForm">
    <fieldset class="adminform">
        <legend>
            Фотография
        </legend>
        <ul class="adminformlist">
            <? foreach ($this->form->getFieldset() as $field): ?>
                <li>
                    <? echo $field->label; echo $field->input; ?>
                </li>
            <? endforeach; ?>
        </ul>
    </fieldset>
    <div>
        <input type="hidden" name="task" value="lrgallery.edit" />
        <? echo JHtml::_('form.token'); ?>
    </div>
</form>