<?php

    defined('_JEXEC') or die('Restricted access');
 
    jimport('joomla.application.component.view');
 
    class lrgalleryViewlrgallery extends JView
    {
        function display($tpl = null) 
        {
            $this->msg = $this->get('Msg');

            if (count($errors = $this->get('Errors'))) 
            {
                JError::raiseError(500, implode('<br />', $errors));
                return false;
            }
            parent::display($tpl);
        }
    }
?>
