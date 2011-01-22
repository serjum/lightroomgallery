<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modeladmin');

    class lrgalleryModelphoto extends JModelAdmin
    {            
        public function getTable($type = 'photo', $prefix = 'lrgalleryTable', $config = array()) 
        {
            return JTable::getInstance($type, $prefix, $config);
        }

        public function getForm($data = array(), $loadData = true) 
        {
            $form = $this->loadForm('com_lrgallery.photo', 'photo', array('control' => 'jform', 'load_data' => $loadData));
            if (empty($form)) 
            {
                return false;
            }
            return $form;
        }
        
        protected function loadFormData() 
        {
            $data = JFactory::getApplication()->getUserState('com_lrgallery.edit.photo.data', array());
            if (empty($data)) 
            {
                $data = $this->getItem();
            }
            return $data;
        }
    }
?>