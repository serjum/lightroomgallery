<?php
    // no direct access
    defined('_JEXEC') or die;

    jimport('joomla.application.component.controllerform');

    class LrgalleryControllerPhotos extends JControllerForm
    {
        /*
         * Название поля метаданных "Флаг принятия" 
         */
        const metaAccepted = "accepted";
        
        /*
         * Название поля метаданных "Рейтинг" 
         */
        const metaRating = "rating";
        
        /*
         * Название поля метаданных "Комментарии" 
         */
        const metaComments = "comments";
        
        /*
         * Установление флага принятия для фотографии
         */
        public function setAcceptedFlag()
        {
            $id = JRequest::getInt('id');
            $flag = JRequest::getString('flag', 'none');
            
            $db =& JFactory::getDBO();
            $flagQ = $db->quote($flag);
            $metaNameQ = $db->quote(self::metaAccepted);
            
            // Проверим, есть ли уже значение этих метаданных
            $db->setQuery("SELECT meta_id
                             FROM #__lrgallery_metadata
                            WHERE photo_id = $id
                              AND meta_id = (
                                    SELECT id
                                      FROM #__lrgallery_meta
                                     WHERE name = $metaNameQ)");
            $metaId = $db->loadResult();
            
            if ($metaId)
            {
                $db->setQuery("UPDATE #__lrgallery_metadata
                                  SET value = $flagQ
                                WHERE photo_id = $id
                                  AND meta_id = $metaId");
            }
            else
            {
                $db->setQuery("INSERT INTO #__lrgallery_metadata
                                (photo_id, meta_id, value)
                               VALUES
                                ($id, (SELECT id
                                         FROM #__lrgallery_meta
                                        WHERE name = $metaNameQ), $flagQ)");
            }
                
            $result = $db->query();
            
            $response = Array('Error' => !$result, 'Message' => $result, 'flag' => $flag);
            $document =& JFactory::getDocument();
            $document->setMimeEncoding( 'application/json' );
            JResponse::setHeader( 'Content-Disposition', 'attachment; filename="'.$this->getName().'.json"' );
            echo json_encode($response);
        }
        
        /*
         * Установка рейтинга фотографии
         */
        public function setRating()
        {
            
        }
        
        /*
         * Установка комментариев фотографии
         */
        public function setComments()
        {
            
        }        
    }
?>    