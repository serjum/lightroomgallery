<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modeladmin');

    class LrgalleryModelUserfolder extends JModelAdmin
    {            
        public function getTable($type = 'userfolder', $prefix = 'lrgalleryTable', $config = array()) 
        {
            return JTable::getInstance($type, $prefix, $config);
        }

        public function getForm($data = array(), $loadData = true) 
        {
            $form = $this->loadForm('com_lrgallery.userfolder', 'userfolder', array('control' => 'jform', 'load_data' => $loadData));
            if (empty($form)) 
            {
                return false;
            }
            return $form;
        }
        
        protected function loadFormData() 
        {
            $data = JFactory::getApplication()->getUserState('com_lrgallery.edit.userfolder.data', array());
            if (empty($data)) 
            {
                $data = $this->getItem();
            }
            return $data;
        }
    }
?>