<?php

    defined('_JEXEC') or die('Restricted access');
 
    jimport('joomla.application.component.view');
 
    class LrgalleryViewPhotos extends JView
    {
        function display($tpl = null) 
        {
            // Получим данные из модели
            $model =& $this->getModel();
            $this->folderBase = $model->folderBase;
            
            $this->user = $this->get('user');
            $this->photos = $this->get('photos');
            $this->metadata = $this->get('metadata');
            
            if (count($errors = $this->get('Errors'))) 
            {
                JError::raiseError(500, implode('<br />', $errors));
                return false;
            }
            
            parent::display($tpl);
        }
    }
?>
