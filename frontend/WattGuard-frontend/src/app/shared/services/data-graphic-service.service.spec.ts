import { TestBed } from '@angular/core/testing';

import { DataGraphicServiceService } from './data-graphic-service.service';

describe('DataGraphicServiceService', () => {
  let service: DataGraphicServiceService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DataGraphicServiceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
