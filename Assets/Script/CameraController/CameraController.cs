using System;
using UnityEngine;

namespace Script
{
    public class CameraController : MonoBehaviour
    {
        private float moveSpeed = 0.5f;
        private float scrollSpeed = 10f;
        private float speed = 3f;
        private float mouseSensitivity = 5;
        
        private float cameraAngle;

        private void Start()
        {
            cameraAngle = 0;
        }

        void Update () {
            transform.Rotate(Vector3.up, Input.GetAxis("Mouse X") * mouseSensitivity, Space.World);
            // transform.Rotate(transform.right, Input.GetAxis("Mouse Y"));
            cameraAngle += -Input.GetAxis("Mouse Y") * mouseSensitivity;
            cameraAngle = Mathf.Clamp(cameraAngle, -90f, 90f);
            transform.eulerAngles =
                new Vector3(cameraAngle, transform.eulerAngles.y, transform.eulerAngles.z);
            if(Input.GetKey(KeyCode.W))
            {
                transform.Translate(Vector3.forward * Time.deltaTime * speed);
            }
            if(Input.GetKey(KeyCode.S))
            {
                transform.Translate(-Vector3.forward * Time.deltaTime * speed);
            }
            if(Input.GetKey(KeyCode.A))
            {
                transform.Translate(-Vector3.right * Time.deltaTime * speed);
            }
            if(Input.GetKey(KeyCode.D))
            {
                transform.Translate(Vector3.right * Time.deltaTime * speed);
            }
            // if(Input.GetKey(KeyCode.LeftArrow))
            // {
            //     transform.Translate(new Vector3(-speed * Time.deltaTime,0,0));
            // }
            if(Input.GetKey(KeyCode.Q))
            {
                transform.Translate(new Vector3(0,-speed * Time.deltaTime,0));
            }
            if(Input.GetKey(KeyCode.E))
            {
                transform.Translate(new Vector3(0,speed * Time.deltaTime,0));
            }

            // if (Input.GetKey(KeyCode.E))
            // {
            //     transform.Translate(Vector3.up * speed, Space.World);
            // }
            // if (Input.GetKey(KeyCode.Q))
            // {
            //     transform.Translate(Vector3.down * speed, Space.World);
            // }
        }
    }
}