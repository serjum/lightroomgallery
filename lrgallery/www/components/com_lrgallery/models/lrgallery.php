<?php

    defined('_JEXEC') or die('Restricted access');

    jimport('joomla.application.component.modelitem');

    class lrgalleryModellrgallery extends JModelItem
    {
        protected $msg;

        public function getMsg() 
        {
            if (!isset($this->msg)) 
            {
                $this->msg = 'Hello World!';
            }
            return $this->msg;
        }
    }
?>