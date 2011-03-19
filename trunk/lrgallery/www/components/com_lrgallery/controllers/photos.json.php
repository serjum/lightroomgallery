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
         * Проверка, проставлено ли уже значение поля метаданных у фотографии
         */
        private function checkMetadata($id, $metaName)
        {
            $db =& JFactory::getDBO();
            $metaNameQ = $db->quote($metaName);
            $db->setQuery("SELECT meta_id
                             FROM #__lrgallery_metadata
                            WHERE photo_id = $id
                              AND meta_id = (
                                    SELECT id
                                      FROM #__lrgallery_meta
                                     WHERE name = $metaNameQ)");
            return $db->loadResult();
        }
        
        /*
         * Получение значения поля метаданных фотографии
         */
        private function getMetadata($id, $metaName)
        {
            $db =& JFactory::getDBO();
            $metaNameQ = $db->quote($metaName);
            $db->setQuery("SELECT value
                             FROM #__lrgallery_metadata
                            WHERE photo_id = $id
                              AND meta_id = (
                                    SELECT id
                                      FROM #__lrgallery_meta
                                     WHERE name = $metaNameQ)");
            $result = $db->loadResult();
            $response = Array('Error' => !$result, 'Message' => $db->stderr(), 'Meta' => $result);
            return $response;
        }
        
        /*
         * Вставка нового значения поля метаданных
         */
        private function insertMetadata($id, $metaName, $data)
        {
            $db =& JFactory::getDBO();
            $metaNameQ = $db->quote($metaName);
            $dataQ = $db->quote($data);
            $db->setQuery("INSERT INTO #__lrgallery_metadata
                                (photo_id, meta_id, value)
                               VALUES
                                ($id, (SELECT id
                                         FROM #__lrgallery_meta
                                        WHERE name = $metaNameQ), $dataQ)");
            $result = $db->query();
            return Array('Error' => !$result, 'Message' => $db->stderr());
        }
        
        /*
         * Обновление значения поля метаданных
         */
        private function updateMetadata($id, $metaId, $data)
        {
            $db =& JFactory::getDBO();
            $dataQ = $db->quote($data);
            $db->setQuery("UPDATE #__lrgallery_metadata
                                  SET value = $dataQ
                                WHERE photo_id = $id
                                  AND meta_id = $metaId");
            $result = $db->query();
            return Array('Error' => !$result, 'Message' => $db->stderr());
        }
        
        /*
         * Вывод ответа в формате JSON
         */
        private function echoResponse($result, $meta)
        {
            $response = Array($result['Error'], 'Message' => $result['Message'], 'meta' => $meta);
            $document =& JFactory::getDocument();
            $document->setMimeEncoding( 'application/json' );
            JResponse::setHeader( 'Content-Disposition', 'attachment; filename="' . 
                    $this->getName() . '.json"' );
            echo json_encode($response);
        }
        
        /*
         * Получение значения поля метаданных фотографии
         */
        public function getMetaValue()
        {
            $id = JRequest::getInt('id');
            $meta = JRequest::getString('meta');
            $result = $this->getMetadata($id, $meta);
            $this->echoResponse($result, $result['Meta']);
        }
        
        /*
         * Установка значения поля метаданных фотографии
         */
        public function setMetaValue()
        {
            $id = JRequest::getInt('id');
            $meta = JRequest::getString('meta');
            $value = JRequest::getString('value');
            
            $metaId = $this->checkMetadata($id, $meta);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $value);
            else
                $result = $this->insertMetadata ($id, $meta, $value);
            
            $this->echoResponse($result, $meta);
        }
        
        /*
         * Получение флага принятия для фотографии
         */
        public function getAcceptedFlag()
        {
            $id = JRequest::getInt('id');
            $flag = $this->getMetadata($id, self::metaAccepted);
            $this->echoResponse($flag, $flag['Meta']);
        }
        
        /*
         * Получение рейтинга для фотографии
         */
        public function getRating()
        {
            $id = JRequest::getInt('id');
            $rating = $this->getMetadata($id, self::metaRating);
            $this->echoResponse($rating, $rating['Meta']);
        }
        
        /*
         * Получение комментариев для фотографии
         */
        public function getComments()
        {
            $id = JRequest::getInt('id');
            $comments = $this->getMetadata($id, self::metaComments);
            $this->echoResponse($comments, $comments['Meta']);
        }
        
        /*
         * Установка флага принятия для фотографии
         */
        public function setAcceptedFlag()
        {
            $id = JRequest::getInt('id');
            $flag = JRequest::getString('flag', 'none');
            
            $metaId = $this->checkMetadata($id, self::metaAccepted);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $flag);
            else
                $result = $this->insertMetadata ($id, self::metaAccepted, $flag);
            
            $this->echoResponse($result, $flag);            
        }
        
        /*
         * Установка рейтинга фотографии
         */
        public function setRating()
        {
            $id = JRequest::getInt('id');
            $rating = JRequest::getInt('rating', 0);
            
            $metaId = $this->checkMetadata($id, self::metaRating);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $rating);
            else
                $result = $this->insertMetadata ($id, self::metaRating, $rating);
            
            $this->echoResponse($result, $rating);
        }
        
        /*
         * Установка комментариев фотографии
         */
        public function setComments()
        {
            $id = JRequest::getInt('id');
            $comments = JRequest::getString('comments', '');
            
            $metaId = $this->checkMetadata($id, self::metaComments);
            if ($metaId)
                $result = $this->updateMetadata ($id, $metaId, $comments);
            else
                $result = $this->insertMetadata ($id, self::metaComments, $comments);
            
            $this->echoResponse($result, $comments);
        }
        
        /*
         * Получение имени файла с фотографией по её ID
         */
        public function getPhotoFileName()
        {
            $id = JRequest::getInt('id', -1);
            $db =& JFactory::getDBO();            
            $db->setQuery("SELECT file_name
                             FROM #__lrgallery_photos
                            WHERE id = $id");
            $result = $db->loadResult();
            $response = Array('Error' => !$result, 'Message' => $db->stderr());
            $this->echoResponse($response, $result);
        }
    }
?>    