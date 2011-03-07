<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.view');

    class LrgalleryViewMetadata extends JView
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
                $isNew = ($this->item->photo_id == 0);
                JToolBarHelper::title($isNew ? "Добавление метаданных" : 
                    "Редактирование метаданных", 'metadata');
                JToolBarHelper::save('metadata.save');
                JToolBarHelper::cancel('metadata.cancel');
        }
    }
?>    