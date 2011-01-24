<?php

    defined('_JEXEC') or die('Restricted Access');

    JHtml::_('behavior.tooltip');
?>

<form action="<?php echo JRoute::_('index.php?option=com_lrgallery'); ?>" method="post" name="adminForm">
    <table class="adminlist">
        <thead>
            <?php echo $this->loadTemplate('head');?>
        </thead>
        <tbody>
            <?php echo $this->loadTemplate('body');?>
        </tbody>
        <tfoot>
            <?php echo $this->loadTemplate('foot');?>
        </tfoot>        
    </table>
    
    <input type="hidden" id="option" name="option" value="com_lrgallery" />
    <input type="hidden" id="task" name="task" value="" />
    <input type="hidden" id="boxchecked" name="boxchecked" value="" />
    <? echo JHtml::_('form.token'); ?>
</form>