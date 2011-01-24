<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.view');

    class LrgalleryViewMetas extends JView
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
            JToolBarHelper::title("Поля метаданных");
            JToolBarHelper::deleteListX('Вы уверены в удалении выбранных полей метаданных?', 'metas.delete');
            JToolBarHelper::editListX('meta.edit');
            JToolBarHelper::addNewX('meta.add');
        }
    }
?>