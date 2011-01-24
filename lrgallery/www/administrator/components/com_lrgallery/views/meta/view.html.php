<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.view');

    class LrgalleryViewMeta extends JView
    {
        public function display($tpl = null) 
        {
            $form = $this->get('Form');
            $item = $this->get('Item');

            if (count($errors = $this->get('Errors'))) 
            {
                JError::raiseError(500, implode('<br />', $errors));
                return false;
            }

            $this->form = $form;
            $this->item = $item;

            $this->addToolBar();
            parent::display($tpl);
        }

        protected function addToolBar() 
        {
                JRequest::setVar('hidemainmenu', true);
                $isNew = ($this->item->id == 0);
                JToolBarHelper::title($isNew ? "Добавление поля метаданных" : 
                    "Редактирование поля метаданных", 'meta');
                JToolBarHelper::save('meta.save');
                JToolBarHelper::cancel('meta.cancel');
        }
    }
?>    