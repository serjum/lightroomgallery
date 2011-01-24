<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modeladmin');

    class LrgalleryModelMeta extends JModelAdmin
    {            
        public function getTable($type = 'meta', $prefix = 'lrgalleryTable', $config = array()) 
        {
            return JTable::getInstance($type, $prefix, $config);
        }

        public function getForm($data = array(), $loadData = true) 
        {
            $form = $this->loadForm('com_lrgallery.meta', 'meta', array('control' => 'jform', 'load_data' => $loadData));
            if (empty($form)) 
            {
                return false;
            }
            return $form;
        }
        
        protected function loadFormData() 
        {
            $data = JFactory::getApplication()->getUserState('com_lrgallery.edit.meta.data', array());
            if (empty($data)) 
            {
                $data = $this->getItem();
            }
            return $data;
        }
    }
?>