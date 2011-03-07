<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modeladmin');

    class LrgalleryModelMetadata extends JModelAdmin
    {            
        public function getTable($type = 'metadata', $prefix = 'lrgalleryTable', $config = array()) 
        {
            return JTable::getInstance($type, $prefix, $config);
        }

        public function getForm($data = array(), $loadData = true) 
        {
            $form = $this->loadForm('com_lrgallery.metadata', 'metadata', array('control' => 'jform', 'load_data' => $loadData));
            if (empty($form)) 
            {
                return false;
            }
            return $form;
        }
        
        protected function loadFormData() 
        {
            $data = JFactory::getApplication()->getUserState('com_lrgallery.edit.metadata.data', array());
            if (empty($data)) 
            {
                $data = $this->getItem();
            }
            return $data;
        }
    }
?>