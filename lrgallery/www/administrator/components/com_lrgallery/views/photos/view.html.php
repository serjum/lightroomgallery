<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.view');

    class LrgalleryViewPhotos extends JView
    {
        function display($tpl = null) 
        {
            $items = $this->get('Items');
            $pagination = $this->get('Pagination');

            if (count($errors = $this->get('Errors'))) 
            {
                JError::raiseError(500, implode('<br />', $errors));
                return false;
            }
            
            $this->items = $items;
            $this->pagination = $pagination;
            
            $this->addToolBar();
            parent::display($tpl);
        }
        
        protected function addToolBar() 
        {
            JToolBarHelper::title("Фотографии", 'photo');
            JToolBarHelper::deleteListX('Вы уверены в удалении выбранных фотографий?', 'photos.delete');
            JToolBarHelper::editListX('photo.edit');
            JToolBarHelper::addNewX('photo.add');
        }
    }
?>